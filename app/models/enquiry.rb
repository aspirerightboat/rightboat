class Enquiry < ActiveRecord::Base

  STATUSES = %w(pending quality_check approved rejected invoiced)

  belongs_to :user
  belongs_to :boat
  belongs_to :invoice

  validates_presence_of :title, :first_name, :surname, :email, :boat_id, :user, :token
  validates_inclusion_of :title, within: User::TITLES, allow_blank: true
  validates_format_of :email, with: /\A[^@]+@[^@]+\z/, allow_blank: true
  validates_uniqueness_of :token, allow_blank: true

  before_validation :generate_token
  before_validation :add_captcha_error

  after_save :send_quality_check_email

  attr_accessor :captcha_correct

  def name
    "#{first_name} #{surname}".strip
  end
  alias_method :to_s, :name

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
      LeadsMailer.delay.lead_quality_check(self) #.deliver_now
    end
  end
end
