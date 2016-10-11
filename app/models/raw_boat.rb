class RawBoat < ApplicationRecord
  has_one :boat

  belongs_to :boat_type
  belongs_to :office
  belongs_to :manufacturer
  belongs_to :model
  belongs_to :country
  belongs_to :currency
  belongs_to :drive_type
  belongs_to :engine_manufacturer
  belongs_to :engine_model
  belongs_to :vat_rate
  belongs_to :fuel_type
  belongs_to :category, class_name: 'BoatCategory'
end
