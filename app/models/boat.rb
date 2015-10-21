class Boat < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper
  include AdvancedSolrIndex

  extend FriendlyId
  friendly_id :slug_candidates, use: [:slugged, :finders]

  attr_accessor :tax_paid, :accept_toc, :agree_privacy_policy

  searchable do
    text :ref_no,               boost: 5
    text :name,                 boost: 4
    text :manufacturer_model,   boost: 3
    text :description,          boost: 0.5
    text :country,              boost: 2
    text :fuel_type,            boost: 2
    text :boat_type,            boost: 2
    text :engine_manufacturer,  boost: 1
    text :engine_model,         boost: 1
    text :drive_type,           boost: 1
    string :ref_no
    string :manufacturer_model
    string :manufacturer
    integer :user_id
    integer :manufacturer_id
    integer :model_id
    string :fuel_type do |boat|
      boat.fuel_type.try(&:name_stripped)
    end
    integer :category_id
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
      boat.poa? ? 0 : Currency.convert(boat.price, boat.currency, Currency.default)
    end
    float :length_m
    boolean :new_boat
    boolean :tax_paid do |boat|
      boat.tax_paid?
    end
    boolean :live do |boat|
      boat.live?
    end
    time :created_at
  end

  has_many :favourites, dependent: :delete_all
  has_many :enquiries, inverse_of: :boat, dependent: :destroy
  has_many :boat_specifications, inverse_of: :boat, dependent: :destroy
  has_many :boat_images, inverse_of: :boat, dependent: :destroy
  has_one :primary_image, -> { order(:position) }, class_name: 'BoatImage'
  has_many :slave_images, -> { order(:position).offset(1) }, class_name: 'BoatImage'
  belongs_to :user,          inverse_of: :boats
  belongs_to :import,        inverse_of: :boats
  belongs_to :office,        inverse_of: :boats
  belongs_to :manufacturer,  inverse_of: :boats
  belongs_to :model,         inverse_of: :boats
  belongs_to :engine_manufacturer,  inverse_of: :boats
  belongs_to :engine_model,  inverse_of: :boats
  belongs_to :category,      inverse_of: :boats, class_name: 'BoatCategory'
  belongs_to :boat_type,     inverse_of: :boats
  belongs_to :drive_type,    inverse_of: :boats
  belongs_to :fuel_type,     inverse_of: :boats
  belongs_to :vat_rate,      inverse_of: :boats
  belongs_to :currency,      inverse_of: :boats
  belongs_to :country,       inverse_of: :boats

  # solr_update_association :country, :manufacturer, :model, :fuel_type, :boat_type, fields: []
  validates_presence_of :manufacturer, :model
  validate :model_inclusion_of_manufacturer
  validate :require_price
  validate :active_of
  validate :violation

  accepts_nested_attributes_for :boat_specifications, reject_if: 'value.blank?'
  accepts_nested_attributes_for :boat_images, reject_if: :all_blank

  scope :featured, -> { where(featured: true) }
  scope :reduced, -> { where(recently_reduced: true) }
  scope :recently_reduced, -> { reduced.limit(3) }

  delegate :tax_paid?, to: :vat_rate, allow_nil: true

  before_destroy :remove_activities

  def self.boat_view_includes; includes(:manufacturer, :currency, :primary_image, :model, :vat_rate) end

  def self.similar_boats(boat, options = {})
    # TODO: need confirmation from RB
    return [] unless boat.manufacturer
    search = Boat.solr_search(include: [:manufacturer, :model, :primary_image]) do |q|
      q.with :live, true
      q.without :ref_no, boat.ref_no
      q.with :manufacturer_id, boat.manufacturer_id
      q.any_of do |q|
        q.all_of do |q|
          q.with :category_id, boat.category_id
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

  def ref_no
    "RB#{100000 + id}"
  end

  def spec_attributes(context = nil, full_spec = false)
    ret = full_spec ? [['Seller', user.name]] : []

    currency = (context.current_currency if context && context.respond_to?(:current_currency))
    l_unit = (context.current_length_unit if context && context.respond_to?(:current_length_unit))

    ret += [
      ['Price', display_price(currency), 'price'],
      ['LOA', display_length(l_unit), 'loa'],
      ['Manufacturer', self.manufacturer],
      ['Model', self.model],
      ['Boat Type', boat_type],
      ['Year Built', self.year_built],
      ['Location', self.country.to_s],
      ['Tax Status', self.tax_status],
      ['Engine make/model', self.engine_model],
      ['Fuel', self.fuel_type]
    ]

    if full_spec
      specs = boat_specifications.includes(:specification)
      specs = specs.front
      ret = specs.inject(ret) {|arr, bs| arr << [bs.specification.to_s, bs.value]; arr}
    else
      specs = Specification.front
      ret = specs.inject(ret) {|arr, s| arr << [s.to_s, s.boat_specifications.where(boat_id: id).first.try(:value)]; arr}
    end
    ret << ['RB Boat Ref', self.ref_no]
    ret.map{|k, v| [k, (v.blank? ? 'N/A' : v)] }
  end

  def full_location
    [location, country.to_s].reject(&:blank?).join(', ')
  end

  def display_length(unit = nil)
    return '' if (length_m.nil? || length_m <= 0)
    unit ||= 'm'
    length = self.length_m.to_f
    length = unit.to_s =~ /ft/i ? length_ft.round : length.round
    "#{length} #{unit}"
  end

  def length_ft
    (length_m * 3.2808399 * 100).round / 100.0
  end

  def display_price(currency = nil)
    if self.poa?
      return I18n.t('poa').html_safe
    else
      currency ||= (self.currency || Currency.default)
      price = Currency.convert(self.price, self.currency, currency)
      number_to_currency(price, unit: currency.symbol.html_safe, precision: 0)
    end
  end

  def live?
    return false if self.deleted?

    manufacturer && model && valid_price?
  end

  def geocoded?
    return false if geo_location.blank? || country_id.nil?
    _l, _, _c = geo_location.rpartition(',')
    _l == location.to_s.downcase ? true : false
  end

  def favourited_by?(user)
    return false unless user
    favourites.where(user: user).exists?
  end

  def valid_price?
    self.poa? || self.price.to_i > 0
  end

  def tax_status
    vat_rate ? vat_rate.tax_status : 'NA'
  end

  def activities
    Activity.where(target_id: id, action: :show)
  end

  def tax_paid=(status)
    self.vat_rate_id = VatRate.first.id if status && status == 'true'
  end

  private
  def slug_candidates
    [
      name,
      manufacturer_model
    ]
  end

  def model_inclusion_of_manufacturer
    if model && model.manufacturer != self.manufacturer
      self.errors.add :model_id, "[#{self.mdoel}] should belongs to manufacturer[#{self.manufacturer}]"
    end
  end

  def require_price
    unless valid_price?
      self.errors.add :price, 'can\'t be blank'
    end
  end

  # featured and reduced attrs are used without solr in some queries
  # so it should be set as true only for live boats
  def active_of
    return if deleted?

    [:featured, :recently_reduced].each do |attr_name|
      if send(attr_name) and !live?
        errors.add attr_name, "can't be set. check manufacturer, model, price and images first"
      end
    end
  end

  def remove_activities
    activities.destroy_all
  end

  def violation
    if accept_toc && accept_toc != '1'
      errors.add :base, 'You should accept Rightboat terms and conditions'
    end

    if agree_privacy_policy && agree_privacy_policy != '1'
      errors.add :base, 'You should agree Rightboat private advert pricing policy.'
    end
  end
end