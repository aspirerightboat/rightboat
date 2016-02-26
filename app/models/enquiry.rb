class Enquiry < ActiveRecord::Base

  STATUSES = %w(pending quality_check approved rejected invoiced)
  BAD_QUALITY_REASONS = %w(bad_contact contact_details_incorrect suspected_spam enquiry_received_twice other)

  # attr_accessor  #:captcha_correct

  belongs_to :user
  belongs_to :boat
  belongs_to :invoice
  belongs_to :accessed_by_broker, class_name: 'User'
  has_many :lead_trails, foreign_key: 'lead_id'

  validates_presence_of :boat_id
  validates_presence_of :email, :first_name, :surname, if: 'user_id.blank?'
  validates_format_of :email, with: /\A\S+@\S+\z/, allow_blank: true

  before_validation :fill_user_info
  # before_validation :add_captcha_error

  before_save :update_lead_price
  after_save :send_quality_check_email
  after_update :create_lead_trail, :admin_reviewed_email

  scope :pending, -> { where(status: 'pending') }
  scope :approved, -> { where(status: 'approved') }
  scope :rejected, -> { where(status: 'rejected') }
  scope :invoiced, -> { where(status: 'invoiced') }
  scope :not_invoiced, -> { where(invoice_id: nil) }

  def name
    [first_name, surname].reject(&:blank?).join(' ')
  end
  alias_method :to_s, :name

  def create_lead_trail(force = false)
    LeadTrail.create!(lead: self, user: $current_user, new_status: status) if force || status_changed?
  end

  def update_lead_price
    self.lead_price = calc_lead_price
    if persisted? && lead_price_changed?
      update_column :lead_price, lead_price
    end
  end

  private

  # def add_captcha_error
  #   errors.add(:captcha, 'is invalid') if captcha_correct != nil && !captcha_correct
  # end

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

  def fill_user_info
    if user_id_changed? && user_id.present?
      self.email = user.email
      self.title = user.title
      self.first_name = user.first_name
      self.surname = user.last_name
      self.phone = user.phone || user.mobile
    end
  end

  def calc_lead_price
    broker_info = boat.user.broker_info
    res = if !boat.poa? && boat.price > 0
            price_gbp = boat.price / boat_currency_rate
            bound = RBConfig[:lead_price_coef_bound] # 500_000
            if price_gbp > bound
              bound * RBConfig[:lead_low_price_coef] + (price_gbp - bound) * RBConfig[:lead_high_price_coef]
            else
              price_gbp * RBConfig[:lead_low_price_coef]
            end
          elsif boat.length_m && boat.length_m > 0
            boat.length_ft * broker_info.lead_length_rate
          else
            RBConfig[:lead_flat_fee]
          end
    res.clamp(broker_info.lead_min_price, broker_info.lead_max_price).round(2)
  end
end
