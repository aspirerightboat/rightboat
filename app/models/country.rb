class Country < ActiveRecord::Base
  include AdvancedSolrIndex
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

  # solr_update_association :boats

  validates_presence_of :iso, :name
  validates_uniqueness_of :iso, :name, allow_blank: true

  searchable do
    string :name
    string :name_ngrme, as: :name_ngrme
  end
  alias_attribute :name_ngrme, :name

  def to_s
    name
  end

  def self.by_priority
    ret = self.where(iso: %w(GB US))
    ret += self.where(iso: %w(AU CA HR DK FR DE GR IE IT NL NZ PL ES SE CH TR)).order(:name)
    ret += self.where('id NOT IN (?)', ret.map(&:id)).order(:name)
    ret
  end

  def self.country_options
    @countries = Rails.cache.fetch "rb.countries", expires_in: 1.day do
      self.by_priority.map { |x| [x.name, x.id]}
    end
  end

  def self.country_code_options
    @country_codes = Rails.cache.fetch "rb.country_codes", expires_in: 1.day do
      self.by_priority.map { |x| [[x.iso.downcase, x.name, x.country_code].join(','), x.country_code]}
    end
  end
end
