class Lead < ApplicationRecord

  STATUSES = %w(pending quality_check approved cancelled invoiced suspicious deleted)
  BAD_QUALITY_REASONS = %w(bad_contact contact_details_incorrect suspected_spam enquiry_received_twice other)

  attr_accessor :suspicious_title

  belongs_to :user
  belongs_to :boat
  belongs_to :invoice
  belongs_to :saved_searches_alert
  belongs_to :accessed_by_broker, class_name: 'User'
  has_many :lead_trails, foreign_key: 'lead_id'
  belongs_to :last_lead_trail, foreign_key: 'last_lead_trail_id', class_name: 'LeadTrail'
  belongs_to :created_from_affiliate, class_name: 'User'
  belongs_to :lead_price_currency, class_name: 'Currency'

  validates_presence_of :boat_id
  validates_presence_of :email, :first_name, :surname, if: 'user_id.blank?'
  validates_format_of :email, with: /\A\S+@\S+\z/, allow_blank: true

  before_validation :fill_user_info

  before_save :set_name
  after_save :send_quality_check_email
  after_save :mail_if_suspicious
  after_save :became_not_suspicious
  after_update :admin_reviewed_email
  after_create :create_lead_trail
  after_update :create_lead_trail, if: :status_changed?

  scope :pending, -> { where(status: 'pending') }
  scope :approved, -> { where(status: 'approved') }
  scope :cancelled, -> { where(status: 'cancelled') }
  scope :invoiced, -> { where(status: 'invoiced') }
  scope :not_invoiced, -> { where(invoice_id: nil) }
  scope :created_from, ->(status, from) { send(status).where('created_at > ?', from) }
  scope :created_between, ->(status, from, to) { send(status).where('created_at BETWEEN ? AND ?', from, to) }
  scope :from_affiliates, -> { where.not(created_from_affiliate: nil) }
  scope :month_eq, ->(month) { where('MONTH(leads.created_at) = ?', month.to_i) }

  def self.ransackable_scopes(_auth_object = nil)
    [:month_eq]
  end

  def to_s
    name
  end

  def create_lead_trail
    lead_trail = LeadTrail.create!(lead: self, user: $current_user, new_status: status)
    update_column(:last_lead_trail_id, lead_trail.id)
  end

  def update_lead_price
    deal = boat.user.deal

    self.lead_price_currency = deal.currency
    self.lead_price_currency_rate = lead_price_currency.rate
    self.lead_price = if deal.within_trial?(new_record? ? Time.current : created_at)
                        0
                      elsif deal.deal_type == 'standard'
                        res = if !boat.poa? && boat.price > 0
                                price = Currency.convert(boat.price, boat.safe_currency, lead_price_currency)
                                bound = RBConfig[:lead_price_coef_bound] # 500_000
                                if price > bound
                                  bound * RBConfig[:lead_low_price_coef] + (price - bound) * RBConfig[:lead_high_price_coef]
                                else
                                  price * RBConfig[:lead_low_price_coef]
                                end
                              elsif (length_ft = boat.length_ft) && length_ft > 0
                                length_ft * deal.lead_length_rate
                              else
                                deal.lead_max_price
                              end
                        res.clamp(deal.lead_min_price..deal.lead_max_price).round(2)
                      elsif deal.deal_type == 'flat_lead'
                        deal.flat_lead_price
                      elsif deal.deal_type == 'flat_month'
                        0
                      end
  end

  def update_lead_price!
    update_lead_price
    save!
  end

  def mark_if_suspicious(user, email, remote_ip)
    if (remote_country = Rightboat::DbIpApi.country(remote_ip))
      suspicious_countries = Country.where(suspicious: true).pluck(:iso)
      if remote_country.in?(suspicious_countries)
        mark_suspicious("Lead from blocked country #{remote_country} – review required")
      end
    end
    last_lead = Lead.where(user ? {user: user} : {remote_ip: remote_ip}).last
    if last_lead && last_lead.created_at > RBConfig[:lead_gap_minutes].minutes.ago
      mark_suspicious('Multiple leads received – review required')
    end
    if Lead.where(status: 'suspicious', email: user&.email || email.presence).exists?
      mark_suspicious('Lead from user with suspicious leads – review required')
    end
  end

  def suspicious?
    status == 'suspicious'
  end

  def handle_lead_created_mails
    LeadCreatedMailsJob.new(id).perform
  end

  def lead_price_gbp
    lead_price / lead_price_currency_rate
  end

  private

  def send_quality_check_email
    if status_changed? && status == 'quality_check'
      StaffMailer.lead_quality_check(id).deliver_later
    end
  end

  def admin_reviewed_email
    if $current_user.try(:admin?) && status_changed? && status.in?(%w(approved cancelled))
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

  def mark_suspicious(mail_title)
    self.status = 'suspicious'
    self.suspicious_title = mail_title
  end

  def mail_if_suspicious
    if status_changed? && status == 'suspicious'
      StaffMailer.suspicious_lead(id, suspicious_title).deliver_later
    end
  end

  def became_not_suspicious
    if status_was == 'suspicious' && status == 'pending'
      handle_lead_created_mails
    end
  end

  def set_name
    self.name = user ? user.name : [title, first_name, surname].reject(&:blank?).map(&:strip).join(' ').titleize
    self.broker = boat.user.company_name
  end

end
