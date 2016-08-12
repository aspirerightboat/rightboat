class Country < ActiveRecord::Base
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
    Country.where(iso: %w(GB DE IT FR ES TR NL BE GR PT SE AT CH DK FI NO IE HR LU IS MC PL RU RO CZ HU)).pluck(:id)
  end

end
