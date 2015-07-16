class Currency < ActiveRecord::Base
  has_many :boats, inverse_of: :currency, dependent: :restrict_with_error
  has_many :countries, inverse_of: :currency, dependent: :restrict_with_error

  validates_presence_of :rate, :name, :symbol

  scope :active, -> { where active: true }

  def self.convert(amount, source_currency, required_currency)
    return amount if source_currency == required_currency
    source_currency ||= Currency.default
    amount * required_currency.rate / source_currency.rate
  end

  def display_symbol
    symbol.to_s.html_safe
  end

  def self.default
    find_by_name('GBP')
  end

end
