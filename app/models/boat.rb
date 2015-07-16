class Boat < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper
  include SunspotRelation

  extend FriendlyId
  friendly_id :slug_candidates, use: [:slugged, :finders]

  searchable do
    integer :id
    text :name,                 boost: 4
    text :manufacturer_model,   boost: 3
    text :description,          boost: 0.5
    text :country,              boost: 2
    text :fuel_type,            boost: 2
    text :boat_type,            boost: 2
    text :engine_manufacturer,  boost: 1
    text :engine_model,         boost: 1
    text :drive_type,           boost: 1
    string :manufacturer_model
    string :manufacturer
    integer :user_id
    integer :manufacturer_id
    integer :model_id
    string :fuel_type do |boat|
      boat.fuel_type.try(&:name_stripped)
    end
    string :boat_type do |boat|
      boat.boat_type.try(&:name_stripped)
    end
    integer :drive_type_id
    integer :country_id
    integer :year do |boat|
      boat.year_built
    end
    float :price do |boat|
      # TODO: make confirm about poa price filter
      boat.poa? ? 0 : boat.price
    end
    float :length_m
    boolean :new_boat
    boolean :tax_paid do |boat|
      boat.tax_paid?
    end
    boolean :live do |boat|
      if boat.manufacturer && boat.model && boat.boat_images.count > 0
        boat.manufacturer.active? && boat.model.active?
      else
        false
      end
    end
  end

  has_many :favourites, inverse_of: :boat, dependent: :destroy
  has_many :liked, class_name: 'User', through: :favourites, source: :user
  has_many :enquiries, inverse_of: :boat, dependent: :destroy
  has_many :boat_specifications, inverse_of: :boat, dependent: :destroy
  has_many :boat_images, inverse_of: :boat, dependent: :destroy
  has_one :primary_image,
          -> { order(:position) },
          class_name: 'BoatImage'
  has_many :slave_images,
          -> { order(:position).offset(1) },
          class_name: 'BoatImage'

  belongs_to :user,          inverse_of: :boats
  belongs_to :import,        inverse_of: :boats
  belongs_to :office,        inverse_of: :boats
  belongs_to :manufacturer,  inverse_of: :boats
  belongs_to :model,         inverse_of: :boats
  belongs_to :engine_manufacturer,  inverse_of: :boats
  belongs_to :engine_model,  inverse_of: :boats
  belongs_to :boat_type,     inverse_of: :boats
  belongs_to :drive_type,    inverse_of: :boats
  belongs_to :fuel_type,     inverse_of: :boats
  belongs_to :vat_rate,      inverse_of: :boats
  belongs_to :currency,      inverse_of: :boats
  belongs_to :country,       inverse_of: :boats

  sunspot_related :country, :manufacturer, :model, :fuel_type, :boat_type
  validates_presence_of :manufacturer, :model

  scope :featured, -> { where featured: true }
  scope :reduced, -> { where(recently_reduced: true) }
  scope :recently_reduced, -> { reduced.limit(3) }
  scope :active, -> { where deleted_at: nil }

  default_scope -> { active }

  def self.similar_boats(boat, options = {})
    # TODO: need confirmation from RB
    return [] unless boat.manufacturer
    search = Sunspot.search Boat do |q|
      q.with :live, true
      q.without :id, [boat.id]
      q.with :manufacturer_id, boat.manufacturer_id
      q.any_of do |q|
        q.all_of do |q|
          q.with :fuel_type_id, boat.fuel_type_id
          q.with :drive_type_id, boat.drive_type_id
        end
        q.with :model_id, boat.model_id if boat.model
      end
      q.paginate page: 1, per_page: options[:limit] || 4
    end
    search.results
  end

  def manufacturer_model
    [manufacturer.to_s, model.to_s].reject(&:blank?).join(' ')
  end

  def to_s
    name.blank? ? manufacturer_model : name
  end

  def spec_attributes(full_spec = false)
    ret = full_spec ? [['Seller', user.name], ['RB Boat Ref', id]] : []

    ret += [
      ['Manufacturer', self.manufacturer],
      ['Model', self.model],
      ['Price', display_price],
      ['Boat Type', boat_type],
      ['Year Built', self.year_built],
      ['Location', self.full_location],
      ['LOA(m)', self.length_m],
      ['Tax Status', self.vat_rate],
      ['Engine make/model', self.engine_model],
      ['Fuel', self.fuel_type]
    ]
    ret = boat_specifications.inject(ret) {|arr, bs| arr << [bs.specification.to_s, bs.value]; arr}
    ret.reject{|_, v| v.blank? }
  end

  def full_location
    [location, country.to_s].reject(&:blank?).join(', ')
  end

  def display_price(currency = nil)
    if self.poa?
      return I18n.t('P.O.A.').html_safe
    else
      currency ||= (self.currency || Currency.default)
      price = Currency.convert(self.price, self.currency, currency)
      number_to_currency(price, unit: currency.symbol.html_safe, precision: 0)
    end
  end

  def favourited_at_by(user)
    self.booked_by(user).try(&:display_ts)
  end

  def booked_by(user)
    return false unless user
    user_id = user.respond_to?(:id) ? user.id : user.to_i
    favourites.where(user_id: user_id).first
  end

  def geocoded?
    return false if geo_location.blank? || country_id.nil?
    _l, _, _c = geo_location.rpartition(',')
    _l == location.to_s.downcase ? true : false
  end

  def booked_by?(user)
    !!self.booked_by(user)
  end

  def tax_paid?
    # TODO: need confirmation from RB
    self.vat_rate.to_s =~ /inc vat|tax paid/i
  end

  private
  def slug_candidates
    [
        name,
        manufacturer_model
    ]
  end

end
