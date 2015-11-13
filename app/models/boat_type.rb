class BoatType < ActiveRecord::Base
  include AdvancedSolrIndex
  include FixSpelling
  include BoatOwner

  GENERAL_TYPES = %w(Power Sail Other)

  # solr_update_association :boats

  validates_presence_of :name
  validates_uniqueness_of :name, allow_blank: true

  searchable do
    string :name
    string :name_ngrme, as: :name_ngrme
  end
  alias_attribute :name_ngrme, :name

  def to_s
    name_stripped
  end

  def name_stripped
    case name.to_s
      when /power|motor|cruiser/i
        'Power'
      when /sail/i
        'Sail'
      else
        'Other'
    end
  end
end
