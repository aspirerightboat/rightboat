class Enquiry < ActiveRecord::Base

  STATUSES = %w(pending quality_check approved rejected invoiced)
  BAD_QUALITY_REASONS = %w(bad_contact other)

  attr_accessor :have_account, :password, :honeypot#, :captcha_correct

  belongs_to :user
  belongs_to :boat
  belongs_to :invoice
  belongs_to :accessed_by_broker, class_name: 'User'
  has_many :lead_trails, foreign_key: 'lead_id'

  validate :check_user
  validates_presence_of :email, :boat_id, :token
  validates_presence_of :title, :first_name, :surname, :user, if: 'have_account == "0"'
  # validates_inclusion_of :title, within: User::TITLES, allow_blank: true
  validates_format_of :email, with: /\A[^@]+@[^@]+\z/, allow_blank: true
  validates_uniqueness_of :token, allow_blank: true

  before_validation :generate_token
  # before_validation :add_captcha_error
  before_validation :check_honeypot

  before_save :update_lead_price
  after_save :send_quality_check_email
  after_update :create_lead_trail
  after_update :admin_reviewed_email

  def self.not_invoiced
    where(invoice_id: nil)
  end

  def name
    "#{first_name} #{surname}".strip
  end
  alias_method :to_s, :name

  def create_lead_trail(force = false)
    LeadTrail.create!(lead: self, user: $current_user, new_status: status) if force || status_changed?
  end

  def update_lead_price
    self.lead_price = calc_lead_price.round(2)
    if persisted? && lead_price_changed?
      update_column :lead_price, lead_price
    end
  end

  private

  def generate_token
    self.token ||= loop do
      random_token = Devise.friendly_token(16)
      break random_token unless Enquiry.exists?(token: random_token)
    end
  end

  # def add_captcha_error
  #   errors.add(:captcha, 'is invalid') if captcha_correct != nil && !captcha_correct
  # end

  def check_honeypot
    errors.add(:honeypot, 'is invalid') unless honeypot.blank?
  end

  def send_quality_check_email
    if status_changed? && status == 'quality_check'
      LeadsMailer.lead_quality_check(id).deliver_later
    end
  end

  def admin_reviewed_email
    if $current_user.try(:admin?) && status_changed? && status.in?(%w(approved rejected))
      LeadsMailer.lead_reviewed_notify_broker(id).deliver_later
    end
  end

  def check_user
    if have_account
      if (existing_user = User.find_by(email: email))
        if existing_user.valid_password?(password)
          self.title = existing_user.try(:title)
          self.first_name = existing_user.try(:first_name)
          self.surname = existing_user.try(:last_name)
          self.phone = existing_user.try(:phone) || existing_user.try(:mobile)
          self.user = existing_user
        else
          errors.add :password, 'is invalid'
        end
      else
        errors.add :email, 'cannot be found'
      end
    end
  end

  def calc_lead_price
    if !boat.poa? && boat.price > 0
      Currency.convert(boat.price, boat.currency, Currency.default) * RBConfig[:lead_price_coef]
    elsif boat.length_m && boat.length_m > 0
      lead_rate = boat.user.broker_info.lead_rate
      Currency.convert(boat.length_ft * lead_rate, Currency.cached_by_name('EUR'), Currency.default)
    else
      RBConfig[:lead_flat_fee]
    end
  end
end
