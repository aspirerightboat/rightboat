class Currency < ActiveRecord::Base

  include AdvancedSolrIndex
  include BoatOwner

  has_many :countries, inverse_of: :currency, dependent: :restrict_with_error

  validates_presence_of :rate, :name, :symbol

  solr_update_association :boats, fields: [:rate]

  scope :active, -> { where(active: true) }
  default_scope -> { order(position: :asc) }

  def self.convert(amount, source_currency, required_currency)
    source_currency ||= Currency.default
    return amount if source_currency == required_currency
    amount.to_f * required_currency.rate / source_currency.rate
  end

  def display_symbol
    symbol.to_s.html_safe
  end

  def self.default
    find_by_name('GBP')
  end

end
