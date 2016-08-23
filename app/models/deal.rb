class Deal < ActiveRecord::Base
  DEAL_TYPES = %w(standard flat_lead flat_month)

  belongs_to :user
  belongs_to :currency

  def setup_flat_lead_deal(currency)
    self.deal_type = 'flat_lead'
    self.currency = currency
    self.flat_lead_price ||= RBConfig[:default_flat_lead_price]
  end

  def processed_charges_text
    txt = charges_text.presence || RBConfig[:"charges_text_#{deal_type}"]
    (txt % deal_params).html_safe
  end

  def deal_params
    case deal_type
    when 'flat_lead' then {flat_lead_price: "#{currency.symbol}#{flat_lead_price.to_i}", currency_iso: currency.name}
    when 'flat_month' then {flat_month_price: "#{currency.symbol}#{flat_month_price.to_i}", currency_iso: currency.name}
    when 'standard'
      broker_info = user.broker_info
      {
          lead_low_price_perc: "#{RBConfig[:lead_low_price_coef] * 100}%",
          lead_high_price_perc: "#{RBConfig[:lead_high_price_coef] * 100}%",
          lead_price_coef_bound: "#{currency.symbol}#{RBConfig[:lead_price_coef_bound].to_i}",
          default_min_lead_price: "#{currency.symbol}#{broker_info.lead_min_price}",
          default_max_lead_price: "#{currency.symbol}#{broker_info.lead_max_price}",
          currency_iso: currency.name,
      }
    end
  end

  def currency
    self[:currency] || Currency.default
  end

  def within_trial?(date)
    trial_started_at && trial_started_at <= date &&
        trial_ended_at &&  date <= trial_ended_at
  end
end
