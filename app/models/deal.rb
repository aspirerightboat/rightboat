class Deal < ApplicationRecord
  DEAL_TYPES = %w(standard flat_lead flat_month)

  belongs_to :user
  belongs_to :currency

  before_save :ensure_deal_params, if: ->(d) { d.new_record? || d.deal_type_changed? }
  before_save :ensure_currency, unless: :currency_id
  after_update :change_leads_price

  def standard?; deal_type == 'standard' end
  def flat_lead?; deal_type == 'flat_lead' end
  def flat_month?; deal_type == 'flat_month' end

  def processed_charges_text
    txt = charges_text.presence || RBConfig[:"charges_text_#{deal_type}"]
    (txt % deal_params).html_safe
  end

  def deal_params
    case deal_type
    when 'flat_lead' then {flat_lead_price: "#{currency.symbol}#{flat_lead_price&.try_skip_fraction}", currency_iso: currency.name}
    when 'flat_month' then {flat_month_price: "#{currency.symbol}#{flat_month_price&.try_skip_fraction}", currency_iso: currency.name}
    when 'standard'
      {
          lead_low_price_perc: "#{RBConfig[:lead_low_price_coef] * 100}%",
          lead_high_price_perc: "#{RBConfig[:lead_high_price_coef] * 100}%",
          lead_price_coef_bound: "#{currency.symbol}#{RBConfig[:lead_price_coef_bound]&.try_skip_fraction}",
          default_min_lead_price: "#{currency.symbol}#{lead_min_price&.try_skip_fraction}",
          default_max_lead_price: "#{currency.symbol}#{lead_max_price&.try_skip_fraction}",
          lead_length_rate: "#{currency.symbol}#{lead_length_rate&.try_skip_fraction}",
          currency_iso: currency.name,
      }
    end
  end

  def within_trial?(date)
    trial_started_at && trial_started_at <= date &&
        trial_ended_at &&  date <= trial_ended_at
  end

  private

  def ensure_deal_params
    case deal_type
    when 'standard'
      self.lead_length_rate ||= 1
      self.lead_min_price ||= RBConfig[:default_min_lead_price]
      self.lead_max_price ||= RBConfig[:default_max_lead_price]
    when 'flat_lead'
      self.flat_lead_price ||= RBConfig[:default_flat_lead_price]
    when 'flat_month'
      self.flat_month_price ||= RBConfig[:default_flat_month_price]
    end
  end

  def ensure_currency
    self.currency = Currency.default
  end

  def change_leads_price
    user.leads.not_deleted.not_invoiced.includes(boat: {user: :deal}).each do |lead|
      lead.update_lead_price!
    end
  end

end
