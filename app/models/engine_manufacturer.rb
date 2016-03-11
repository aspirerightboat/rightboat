class EngineManufacturer < ActiveRecord::Base
  include FixSpelling
  include BoatOwner

  has_many :engine_models, inverse_of: :engine_manufacturer, dependent: :restrict_with_error

  validates_presence_of :name
  validates_uniqueness_of :name, allow_blank: true

end
