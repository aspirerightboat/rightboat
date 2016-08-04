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
    if country_iso.in? [
                           'AT', # Austria => EUR
                           'BE', # Belgium => EUR
                           'CY', # Cyprus => EUR
                           'EE', # Estonia => EUR
                           'FI', # Finland => EUR
                           'FR', # France => EUR
                           'DE', # Germany => EUR
                           'GR', # Greece => EUR
                           'IE', # Ireland => EUR
                           'IT', # Italy => EUR
                           'LV', # Latvia => EUR
                           'LT', # Lithuania => EUR
                           'LU', # Luxembourg => EUR
                           'MT', # Malta => EUR
                           'NL', # Netherlands => EUR
                           'PT', # Portugal => EUR
                           'ES', # Spain => EUR
                           'SI', # Slovenia => EUR
                           'SK', # Slovakia => EUR
                           # other
                           'TR', # Turkey => TRY
                           'SE', # Sweden => SEK
                           'CH', # Switzerland => CHF
                           'DK', # Denmark => DKK
                           'NO', # Norway => NOK
                           'HR', # Croatia => nil
                           'IS', # Iceland => nil
                           'MC', # Monaco => EUR
                           'PL', # Poland => PLN
                           'RO', # Romania => RON
                           'CZ', # Czech Republic => CZK
                           'HU', # Hungary => HUF
                       ]
      find_by(name: 'EUR')
    elsif country_iso == 'GB'
      find_by(name: 'GBP')
    else
      find_by(name: 'USD')
    end
  end

end
