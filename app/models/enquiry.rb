class Enquiry < ActiveRecord::Base

  STATUSES = %w(pending quality_check approved rejected invoiced)
  BAD_QUALITY_REASONS = %w(bad_contact other)

  belongs_to :user
  belongs_to :boat
  belongs_to :invoice
  has_many :lead_trails, foreign_key: 'lead_id'

  validates_presence_of :title, :first_name, :surname, :email, :boat_id, :user, :token
  validates_inclusion_of :title, within: User::TITLES, allow_blank: true
  validates_format_of :email, with: /\A[^@]+@[^@]+\z/, allow_blank: true
  validates_uniqueness_of :token, allow_blank: true

  before_validation :generate_token
  before_validation :add_captcha_error

  after_save :send_quality_check_email
  after_update :create_lead_trail

  attr_accessor :captcha_correct

  def name
    "#{first_name} #{surname}".strip
  end
  alias_method :to_s, :name

  def create_lead_trail(force = false)
    LeadTrail.create!(lead: self, user: $current_user, new_status: status) if force || status_changed?
  end

  private

  def generate_token
    self.token ||= loop do
      random_token = Devise.friendly_token(16)
      break random_token unless Enquiry.exists?(token: random_token)
    end
  end

  def add_captcha_error
    errors.add(:captcha, 'is invalid') if captcha_correct != nil && !captcha_correct
  end

  def send_quality_check_email
    if status_changed? && status == 'quality_check'
      LeadsMailer.lead_quality_check(self).deliver_later
    end
  end
end
