class Enquiry < ActiveRecord::Base

  attr_accessor :have_account, :password

  belongs_to :user, inverse_of: :enquiries
  belongs_to :boat, inverse_of: :enquiries

  validate :check_user
  validates_presence_of :title, :first_name, :surname, :email, :boat_id, :token
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
end
