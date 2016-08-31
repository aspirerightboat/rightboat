class User < ActiveRecord::Base
  extend FriendlyId
  friendly_id :slug_candidates, use: [:slugged, :finders]

  TITLES = %w(Mr Mrs Miss Ms Capt Dr Sir)

  ROLES = {
      'PRIVATE' => 0,
      'COMPANY' => 2,
      'ADMIN' => 99
  }

  serialize :broker_ids, Array

  scope :active, -> { where active: true }
  scope :inactive, -> { where active: false }
  scope :general, -> { where(role: ROLES['PRIVATE']) }
  scope :companies, -> { where(role: ROLES['COMPANY']).order(:company_name) }
  scope :not_companies, -> { where.not(role: ROLES['COMPANY']) }

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_one :address, as: :addressible, dependent: :destroy
  has_many :offices, inverse_of: :user, dependent: :destroy
  has_many :user_activities
  has_many :leads, inverse_of: :user, dependent: :nullify
  has_many :broker_leads, through: :boats, source: :leads
  has_many :imports, inverse_of: :user, dependent: :destroy
  has_many :boats, inverse_of: :user, dependent: :destroy
  has_many :favourites, dependent: :delete_all
  has_many :berth_enquiries, dependent: :destroy
  has_many :insurances, dependent: :destroy
  has_many :finances, dependent: :destroy
  has_one :information, class_name: 'UserInformation', inverse_of: :user, dependent: :destroy
  has_one :broker_info, dependent: :destroy
  has_one :user_alert, dependent: :destroy
  has_many :invoices, dependent: :nullify
  has_many :lead_trails, dependent: :nullify
  has_many :saved_searches, dependent: :delete_all
  has_many :exports, dependent: :delete_all
  has_many :mail_clicks
  has_one :user_setting
  has_many :created_manufacturers, class_name: 'Manufacturer', foreign_key: 'created_by_user_id'
  has_many :created_models, class_name: 'Model', foreign_key: 'created_by_user_id'
  has_many :deleted_boats, class_name: 'Boat', foreign_key: :deleted_by_user_id
  has_many :broker_iframes
  belongs_to :registered_from_affiliate, class_name: 'User'
  has_one :stripe_card, dependent: :destroy
  has_one :facebook_user_info, dependent: :destroy
  has_one :deal, dependent: :destroy
  has_many :special_requests, dependent: :destroy

  mount_uploader :avatar, AvatarUploader

  accepts_nested_attributes_for :address, allow_destroy: true
  accepts_nested_attributes_for :information, allow_destroy: true
  accepts_nested_attributes_for :offices, allow_destroy: true
  accepts_nested_attributes_for :broker_info, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :deal, allow_destroy: true

  # validates_inclusion_of :title, within: TITLES, allow_blank: true

  validates_presence_of :first_name, :last_name, unless: :company?
  validates_presence_of :company_name, if: :company?
  # validates_uniqueness_of :email, if: ->(u) { u.new_record? || u.email_changed? } # devise already validates email
  validates_url :company_weburl, allow_blank: true, if: :company?

  before_create { build_user_alert } # will create user_alert
  before_save :create_broker_info
  before_validation :ensure_username
  before_save :ensure_deal, if: ->(u) { u.new_record? || u.role_changed? }
  after_save :reconfirm_email_if_changed, unless: :updated_by_admin
  after_create :send_email_confirmation, unless: :updated_by_admin
  after_create :send_new_email, if: :private?
  after_create :personalize_leads
  attr_accessor :updated_by_admin, :current_password

  delegate :country, to: :address, allow_nil: true

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

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def name_with_title
    "#{title} #{first_name} #{last_name}".strip.titleize
  end

  def name
    company? ? company_name : full_name
  end
  alias_method :to_s, :name
  alias_method :display_name, :name # for active_admin

  def private?; role == ROLES['PRIVATE'] end
  def company?; role == ROLES['COMPANY'] end
  def admin?; role == ROLES['ADMIN'] end

  def confirm_email_token
    Digest::MD5.hexdigest("#{email}RightBoatSalt")
  end

  def customer_detail_requested?
    special_requests.customer_detail.any?
  end

  def boat_year_requested?
    special_requests.boat_year.any?
  end

  def comment_requested?
    special_requests.comment.any?
  end

  def loa_requested?
    special_requests.loa.any?
  end

  def send_email_confirmation
    UserMailer.email_confirmation(id).deliver_now if !company?
  end

  def payment_method_present?
    broker_info.payment_method != 'none'
  end

  def broker_name
    broker_info.try(:contact_name) || name
  end

  def broker?
    company?
  end

  def assign_phone_from_leads
    if phone.blank?
      lead = Lead.where(email: email).where("phone IS NOT NULL AND phone <> ''").first
      self.phone = [lead.country_code.presence, lead.phone.gsub(/\D/, '')].compact.join('-') if lead
    end
  end

  def personalize_leads
    Lead.where(email: email, user_id: nil).each do |lead|
      lead.update(user_id: id)
      UserActivity.create(kind: 'lead',
                          lead_id: lead.id,
                          user_id: id,
                          user_email: email,
                          created_at: lead.created_at)
    end
  end

  private

  def slug_candidates
    [(company_name if company?), [first_name, last_name], email]
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if (login = conditions.delete(:email))
      where(conditions.to_h).where(['username = :value OR email = :value', {value: login}]).first
    else
      where(conditions.to_h).first
    end
  end

  def create_broker_info
    if role_changed?
      if company?
        self.broker_info ||= build_broker_info
      else
        BrokerInfo.where(user_id: id).delete_all
      end
    end
    true
  end

  def reconfirm_email_if_changed
    if email_changed? && !id_changed?
      update_column(:email_confirmed, false)
      send_email_confirmation
    end
    true
  end

  def send_new_email
    StaffMailer.new_private_user(id).deliver_now
  end

  def ensure_username
    if username.blank?
      str = name.downcase.squeeze.gsub(' ', '-').gsub(/[^\w@.-]/, '')
      str = "u-#{str}" if str !~ /\A[a-zA-Z]/
      self.username = str
    end
  end

  def ensure_deal
    if company? && !deal
      create_deal(
          deal_type: 'flat_lead',
          currency: Currency.deal_currency_by_country(country&.iso)
      )
    elsif !company? && deal
      deal.destroy
    end
  end
end
