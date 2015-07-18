class EngineModel < ActiveRecord::Base
  include AdvancedSolrIndex
  include FixSpelling

  has_many :boats, inverse_of: :engine_model, dependent: :restrict_with_error

  belongs_to :engine_manufacturer, inverse_of: :engine_models

  solr_update_association :boats

  validates_presence_of :name
  validates_uniqueness_of :name, scope: :engine_manufacturer_id, allow_blank: true

  scope :active, -> { where active: true }

  def to_s
    name
  end

end
