class Enquiry < ActiveRecord::Base

  belongs_to :user, inverse_of: :enquiries
  belongs_to :boat, inverse_of: :enquiries

  validates_presence_of :title, :first_name, :surname, :email, :boat_id, :user, :token
  # validates_inclusion_of :title, within: User::TITLES, allow_blank: true
  validates_format_of :email, with: /\A[^@]+@[^@]+\z/, allow_blank: true
  validates_uniqueness_of :token, allow_blank: true

  before_validation :generate_token

  def name
    [first_name, surname].reject(&:blank?).join(' ')
  end
  alias_method :to_s, :name

  def self.pepper
    Figaro.env.captcha_salt
  end

  def self.stretches
    10
  end

  private
  def generate_token
    self.token ||= loop do
      random_token = Devise.friendly_token(16)
      break random_token unless self.class.exists?(token: random_token)
    end
  end
end
