class BoatTemplate < ActiveRecord::Base
  serialize :from_boats, Array
  serialize :specs

  belongs_to :manufacturer
  belongs_to :model
  belongs_to :engine_manufacturer
  belongs_to :engine_model
  belongs_to :boat_type
  belongs_to :drive_type
  belongs_to :fuel_type

  def self.find_or_try_create(manufacturer_id, model_id)
    template = where(manufacturer_id: manufacturer_id, model_id: model_id).first
    if !template
      boats = Boat.where(manufacturer_id: manufacturer_id, model_id: model_id, published: true)
                  .includes(:currency, boat_specifications: :specification).to_a
      template = if boats.one?
                   new(automatic: true).initialize_from_boat(boats.first)
                 elsif boats.many?
                   create_from_boats(boats)
                 end
    end
    template
  end

  def initialize_from_boat(boat)
    self.from_boats ||= []
    self.from_boats << boat.id
    self.manufacturer_id ||= boat.manufacturer_id
    self.model_id ||= boat.model_id
    self.year_built ||= boat.year_built
    if !boat.poa? && boat.price > 0
      boat_price_gbp = Currency.convert(boat.price, boat.currency, Currency.default)
      self.price = if price > 0
                     (boat_price_gbp + price) / 2
                   else
                     boat_price_gbp
                   end
    end
    self.length_m ||= boat.length_m
    self.short_description ||= boat.short_description
    self.description ||= boat.description
    self.boat_type_id ||= boat.boat_type_id
    self.drive_type_id ||= boat.drive_type_id
    self.engine_manufacturer_id ||= boat.engine_manufacturer_id
    self.engine_model_id ||= boat.engine_model_id
    self.fuel_type_id ||= boat.fuel_type_id
    self.specs ||= {}
    boat.boat_specifications.each do |boat_spec|
      self.specs[boat_spec.specification.name] ||= boat_spec.value
    end
  end

  def self.create_from_boats(boats)
    t = new(automatic: true)
    boats.each { |boat| t.initialize_from_boat(boat) }
    t.save!
    t
  end
end
