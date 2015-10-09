class Country < ActiveRecord::Base
  include AdvancedSolrIndex
  include FixSpelling
  include BoatOwner

  extend FriendlyId
  friendly_id :name, use: [:slugged, :finders]

  belongs_to :currency, inverse_of: :countries

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

  def self.country_code_options
    @@country_code_options ||= Country.order(:name).map { |x| ["#{x.name} (+#{x.country_code})", x.country_code]}
  end
end
