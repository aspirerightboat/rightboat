class User < ActiveRecord::Base
  extend FriendlyId
  friendly_id :slug_candidates, use: [:slugged, :finders]

  TITLES = ['Mr', 'Sir', 'Miss', 'Ms', 'Mrs', 'Doctor']

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
  has_many :favourites, inverse_of: :user, dependent: :destroy
  has_many :saved_boats, class_name: 'Boat', through: :favourites
  has_and_belongs_to_many :subscriptions

  mount_uploader :avatar, AvatarUploader

  accepts_nested_attributes_for :address, allow_destroy: true

  validates_presence_of :username, :first_name, :last_name
  validates_uniqueness_of :username, allow_blank: true
  validates_format_of :username, with: /\A[a-zA-Z][\w\d\-]+\z/, allow_blank: true
  validates_inclusion_of :title, within: TITLES, allow_blank: true

  after_create :create_subscriptions!

  delegate :country, to: :address

  def role=(r)
    (r.is_a?(String) && r =~ /^\w+$/) ? write_attribute(:role, ROLES[r].to_i) : super(r)
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

  def admin?
    self.role.to_i == ROLES['ADMIN']
  end

  def company?
    self.role.to_i == ROLES['COMPANY']
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

  def create_subscriptions!
    self.subscription_ids = Subscription.all.map(&:id)
  end
end
