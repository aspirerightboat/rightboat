class DriveType < ActiveRecord::Base
  include AdvancedSolrIndex
  include FixSpelling
  include BoatOwner

  # solr_update_association :boats

  validates_presence_of :name
  validates_uniqueness_of :name, allow_blank: true

end
