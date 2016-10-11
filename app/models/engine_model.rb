class EngineModel < ApplicationRecord
  include FixSpelling
  include BoatOwner

  belongs_to :engine_manufacturer, inverse_of: :engine_models
  belongs_to :created_by_user, class_name: 'User'

  validates_presence_of :name
  validates_uniqueness_of :name, scope: :engine_manufacturer_id, allow_blank: true

  def to_s
    name
  end

end
