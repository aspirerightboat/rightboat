class User < ActiveRecord::Base
  extend FriendlyId
  friendly_id :slug_candidates, use: [:slugged, :finders]

  TITLES = %w(Mr Sir Miss Ms Mrs Dr Captain Sheik)

  ROLES = {
      'PRIVATE' => 0,
      'MANUFACTURER' => 1,
      'COMPANY' => 2,
      'ADMIN' => 99
  }
  scope :companies, -> { where(role: ROLES['COMPANY']).order(:company_name) }
  scope :organizations, -> { where(role: [ROLES['COMPANY'], ROLES['MANUFACTURER']]).order(:company_name) }

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_one :address, as: :addressible, dependent: :destroy
  has_many :offices, inverse_of: :user, dependent: :destroy
  has_many :enquiries, inverse_of: :user, dependent: :nullify
  has_many :imports, inverse_of: :user, dependent: :destroy
  has_many :boats, inverse_of: :user, dependent: :destroy
  has_many :favourites, dependent: :delete_all
  has_one :information, class_name: 'UserInformation', inverse_of: :user, dependent: :destroy
  has_one :broker_info, dependent: :destroy
  has_one :user_alert, dependent: :destroy
  has_many :invoices, dependent: :nullify
  has_many :lead_trails, dependent: :nullify
  has_many :saved_searches, dependent: :delete_all

  mount_uploader :avatar, AvatarUploader

  accepts_nested_attributes_for :address, allow_destroy: true
  accepts_nested_attributes_for :information, allow_destroy: true

  validates_presence_of :username
  validates_uniqueness_of :username, allow_blank: true
  validates_format_of :username, with: /\A[a-zA-Z][\w@.-]+\z/, allow_blank: true
  validates_inclusion_of :title, within: TITLES, allow_blank: true

  validates_presence_of :first_name, :last_name, unless: :organization?
  validates_presence_of :company_name, :company_weburl, :company_description, if: :organization?
  validates_url :company_weburl, allow_blank: true, if: :organization?

  before_create { build_user_alert } # will create user_alert
  before_save :create_broker_info

  delegate :country, to: :address

  def role=(r)
    if r.is_a?(String)
      if r =~ /^\d+$/
        write_attribute(:role, r.to_i)
      elsif r =~ /^\w+$/
        write_attribute(:role, ROLES[r].to_i)
      else
        super
      end
    else
      super
    end
  end

  def role_name
    self.class::ROLES.invert[self.role.to_i]
  end

  def name
    if company?
      company_name
    else
      [first_name, last_name].join(' ').strip
    end
  end
  alias_method :to_s, :name

  ROLES.each do |role_name, _|
    define_method "#{role_name.to_s.underscore}?" do
      self.role.to_i == ROLES[role_name.to_s]
    end
  end

  def organization?
    self.company? || self.manufacturer?
  end

  private
  def slug_candidates
    [
        username,
        [first_name, last_name],
        [email]
    ]
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:email)
      where(conditions.to_h).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    else
      where(conditions.to_h).first
    end
  end

  def create_broker_info
    if role_changed?
      if company?
        BrokerInfo.find_or_create_by(user_id: id)
      else
        BrokerInfo.where(user_id: id).delete_all
      end
    end
  end
end
