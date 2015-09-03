class EngineModel < ActiveRecord::Base
  include AdvancedSolrIndex
  include FixSpelling
  include BoatOwner

  belongs_to :engine_manufacturer, inverse_of: :engine_models

  solr_update_association :boats

  validates_presence_of :name
  validates_uniqueness_of :name, scope: :engine_manufacturer_id, allow_blank: true

  scope :active, -> { where active: true }

  def to_s
    name
  end

end
