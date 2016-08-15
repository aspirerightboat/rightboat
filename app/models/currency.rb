class Currency < ActiveRecord::Base
  include BoatOwner

  has_many :countries, inverse_of: :currency, dependent: :restrict_with_error
  has_many :deals

  validates_presence_of :rate, :name, :symbol

  default_scope -> { order(:position) }

  def self.convert(amount, source_currency, required_currency)
    return 0 unless amount
    source_currency ||= Currency.default
    return amount if source_currency == required_currency
    amount * required_currency.rate / source_currency.rate
  end

  def self.cached_by_name(name)
    @cached_by_name ||= Currency.select('id, name, rate, symbol').index_by(&:name)
    @cached_by_name[name]
  end

  def display_symbol
    symbol.to_s.html_safe
  end

  def self.default
    cached_by_name('GBP')
  end

  def self.deal_currency_by_country(country_iso)
    case country_iso
    when *Country::EUROPEAN_ISO_CODES then find_by(name: 'EUR')
    when 'GB' then find_by(name: 'GBP')
    else find_by(name: 'USD')
    end
  end

end
