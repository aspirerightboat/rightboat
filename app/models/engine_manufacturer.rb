class EngineManufacturer < ActiveRecord::Base
  include SunspotRelation
  include FixSpelling

  has_many :engine_models, inverse_of: :engine_manufacturer, dependent: :restrict_with_error
  has_many :boats, inverse_of: :engine_manufacturer, dependent: :restrict_with_error

  sunspot_related :boats

  validates_presence_of :name
  validates_uniqueness_of :name, allow_blank: true

  scope :active, -> { where active: true }

end
