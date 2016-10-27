class BrokerInfo < ApplicationRecord
  LEAD_EMAIL_DISTRIBUTIONS = %w(user_and_office user_only office_only)
  PAYMENT_METHODS = %w(none card dd none_lead)

  serialize :additional_email, Array
  attr_accessor :additional_email_raw

  belongs_to :user

  mount_uploader :logo, BrokerLogoUploader

  after_validation :remove_logo!, if: 'remove_logo == "true"'

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

  def self.privatee_broker_fee(country_iso)
    res = {currency: Currency.deal_currency_by_country(country_iso)}
    case country_iso
    when *Country::EUROPEAN_ISO_CODES then res.merge!(price: 18)
    when 'GB' then res.merge!(price: 15, vat: 3)
    else res.merge!(price: 18)
    end
  end

end
