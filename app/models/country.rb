class Country < ActiveRecord::Base
  EUROPEAN_ISO_CODES = [
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
  US_COUNTRY_ID = find_by(iso: 'US').id
  include FixSpelling
  include BoatOwner

  extend FriendlyId
  friendly_id :name, use: [:slugged, :finders]

  belongs_to :currency, inverse_of: :countries

  scope :query_with_aliases, -> (value) {
    q = joins("LEFT JOIN misspellings ON source_type = '#{name}' AND source_id = #{table_name}.id")
    q = q.where("#{table_name}.name = :name OR misspellings.alias_string = :name OR #{table_name}.iso = :name", name: value)
    q.create_with(name: value)
  }

  validates_presence_of :iso, :name
  validates_uniqueness_of :iso, :name, allow_blank: true

  def to_s
    name
  end

  def aliases
    [name, iso, iso3] + misspellings.pluck(:alias_string)
  end

  def self.by_priority # TODO: make priority column
    ret = self.where(iso: %w(GB US))
    ret += self.where(iso: %w(AU CA HR DK FR DE GR IE IT NL NZ PL ES SE CH TR)).order(:name)
    ret += self.where('id NOT IN (?)', ret.map(&:id)).order(:name)
    ret
  end

  def self.country_options
    @country_options ||= by_priority.map { |x| [x.name, x.id] }
  end

  def self.country_code_options
    @country_code_options ||= by_priority.map { |x| [x.name, x.iso.downcase, x.country_code] }
  end

  def self.european_country_ids
    Country.where(iso: EUROPEAN_ISO_CODES).pluck(:id)
  end

end
