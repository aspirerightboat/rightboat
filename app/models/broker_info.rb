class BrokerInfo < ActiveRecord::Base
  LEAD_EMAIL_DISTRIBUTIONS = %w(user_and_office user_only office_only)
  PAYMENT_METHODS = %w(none card dd)

  serialize :additional_email, Array
  attr_accessor :additional_email_raw

  belongs_to :user

  mount_uploader :logo, BrokerLogoUploader

  after_save :change_lead_price
  before_create :assign_default_values

  def distribution_options
    if user && user.source == 'eyb' && user.imports.active.any?
      LEAD_EMAIL_DISTRIBUTIONS + ['user_and_eyb']
    else
      LEAD_EMAIL_DISTRIBUTIONS
    end
  end

  def additional_email_raw
    self.additional_email.join(',')
  end

  def additional_email_raw=(values)
    self.additional_email = values.split(',')
  end

  private

  def change_lead_price
    if lead_length_rate_changed? || lead_min_price_changed? || lead_max_price_changed?
      user.leads.not_deleted.not_invoiced.each do |lead|
        lead.update_lead_price
      end
    end
  end

  def assign_default_values
    self.lead_min_price = RBConfig[:default_min_lead_price]
    self.lead_max_price = RBConfig[:default_max_lead_price]
  end

end
