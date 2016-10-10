class Boat < ActiveRecord::Base
  enum status: [:active, :inactive]
  OFFER_STATUSES = %w(available under_offer sold)
  VOLUME_UNITS = %w(gallons litres)
  WEIGHT_UNITS = %w(kgs lbs tonnes)
  SPEED_UNITS = %w(knots mph rpm)
  LENGTH_UNITS = %w(ft m)
  YEARS_RANGE = (Date.today.year - 200)..Date.today.year
  PRICES_RANGE = 0..100_000_000
  M_LENGTHS_RANGE = 0..300
  FT_LENGTHS_RANGE = 0..1000

  searchable do
    text :ref_no,               boost: 5
    text :manufacturer,         boost: 4
    text :manufacturer_model,   boost: 3.5
    text :model,                boost: 3
    text :name,                 boost: 2.5
    text :country,              boost: 2
    text :fuel_type,            boost: 2
    text :boat_type,            boost: 2
    text :engine_manufacturer,  boost: 1
    text :engine_model,         boost: 1
    text :drive_type,           boost: 1
    text(:description,          boost: 0.5) { |boat| boat.extra.description }
    string(:ref_no) { |boat| boat.ref_no.downcase }
    string(:manufacturer_model) { |boat| boat.manufacturer_model.downcase }
    string(:manufacturer) { |boat| boat.manufacturer.name.downcase }
    string(:model) { |boat| boat.model.name.downcase }
    string(:fuel_type) { |boat| boat.fuel_type&.name_stripped }
    string(:boat_type) { |boat| boat.boat_type&.name_stripped }
    string(:state) { |boat| boat.state&.downcase }
    integer :user_id
    integer :manufacturer_id
    integer :model_id
    integer :category_id
    integer :drive_type_id
    integer :country_id
    integer :boat_type_id
    integer(:year, as: :year_sml_int) { |boat| boat.year_built } # *_sml_int is configured in solr schema.xml with sortMissingLast="true"
    float(:price) { |boat| boat.price_gbp || 0 }
    float :length_m
    boolean :new_boat
    boolean(:tax_paid) { |boat| boat.tax_paid? }
    boolean(:live) { |boat| boat.active? }
    time :created_at
  end

  before_validation :change_status, :ensure_offer_status
  before_destroy :remove_activities, :decrease_counter_cache
  after_save :update_leads_price
  after_save :notify_changed
  before_destroy :notify_destroyed # this callback should be before "has_many .., dependent: :destroy" associations
  after_create :assign_slug, :ensure_extra
  after_destroy :destroy_slave_images

  has_many :favourites, dependent: :delete_all
  has_many :leads
  has_many :boat_specifications
  accepts_nested_attributes_for :boat_specifications, reject_if: 'value.blank?'
  has_many :boat_images, -> { order(:position, :id) }
  accepts_nested_attributes_for :boat_images, reject_if: :all_blank
  has_one :primary_image, -> { not_deleted.order(:position, :id) }, class_name: 'BoatImage'
  has_many :slave_images, -> { not_deleted.order(:position, :id).offset(1) }, class_name: 'BoatImage'
  belongs_to :user
  has_many :user_activities
  belongs_to :import
  belongs_to :office
  belongs_to :manufacturer
  belongs_to :model
  belongs_to :engine_manufacturer
  belongs_to :engine_model
  belongs_to :category, class_name: 'BoatCategory'
  belongs_to :boat_type
  belongs_to :drive_type
  belongs_to :fuel_type
  belongs_to :vat_rate
  belongs_to :currency
  belongs_to :country
  has_many :old_slugs, as: :sluggable, dependent: :delete_all
  has_many :class_groups, class_name: 'BoatClassGroup'
  has_many :media, class_name: 'BoatMedium'
  belongs_to :deleted_by_user, class_name: 'User'
  has_one :extra, class_name: 'BoatExtra', dependent: :destroy
  accepts_nested_attributes_for :extra

  validates_presence_of :manufacturer, :model
  validate :valid_manufacturer_model
  validate :valid_price
  validate :valid_featured

  include BoatOverridableFields

  scope :featured, -> { where(featured: true) }
  scope :reduced, -> { where(recently_reduced: true) }
  scope :recently_reduced, -> { reduced.limit(3) }
  scope :recently_viewed, -> (user) do
    joins(:user_activities)
        .where(user_activities: {kind: :boat_view, user_id: user.id})
        .order('user_activities.id DESC').uniq
  end
  scope :with_boat_types, -> { joins('LEFT JOIN boat_types ON boats.boat_type_id = boat_types.id') }
  scope :power, -> { with_boat_types.where(boat_types: { name_stripped: 'power' }) }
  scope :sail, -> { with_boat_types.where(boat_types: { name_stripped: 'sail' }) }
  scope :not_power_or_sail, -> { with_boat_types.where(boat_types: { name_stripped: 'other' }) }
  scope :country_or_all, ->(country) { where(country: country) if country }

  delegate :tax_paid?, to: :vat_rate, allow_nil: true

  def self.boat_view_includes; includes(:manufacturer, :currency, :primary_image, :model, :vat_rate) end

  def to_param; slug end

  def similar_options(required_currency = nil, length_unit = nil)
    length_unit ||= 'm'
    options = {
        exclude_ref_no: ref_no,
        boat_type:  boat_type&.name_stripped,
        length_unit: length_unit
    }

    if !poa?
      required_price = required_currency ? Currency.convert(price, safe_currency, required_currency) : price
      options[:currency] = currency&.name
      options[:price_min] = (required_price * 0.8).to_i
      options[:price_max] = (required_price * 1.2).to_i
    end

    if (length = length_m)
      length = length.m_to_ft.round if options[:length_unit] == 'ft'
      options[:length_min] = (length * 0.8).round(2)
      options[:length_max] = (length * 1.2).round(2)
    end

    options
  end

  def other_options
    {manufacturer_id: manufacturer_id, model_id: model_id, exclude_ref_no: ref_no}
  end

  def manufacturer_model
    "#{manufacturer.name} #{model.name if model.name != 'Unknown'}".strip
  end

  def short_makemodel_fileslug(max_length = 25)
    name = "#{manufacturer.name} #{model.name}"
    name = manufacturer.name if name.size > max_length
    name.gsub!(/[^\w-]/, '-')
    name.squeeze!('-')
    name.gsub!(/\A-/, '')
    name.gsub!(/-\z/, '')
    name
  end

  def display_name
    name.blank? ? manufacturer_model : name
  end

  def to_s
    display_name
  end

  def ref_no
    "RB#{100000 + id}"
  end

  def self.id_from_ref_no(ref_no)
    ref_no[/.*rb(\d+)\z/i, 1].to_i - 100000
  end

  def full_location
    [location, country&.name].reject(&:blank?).join(', ')
  end

  def length_ft
    if length_f
      length_f.round(2)
    elsif length_m
      length_m.m_to_ft.round(2)
    end
  end

  def geocoded?
    geo_location && location.present? && geo_location.rpartition(', ')[0] == location
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

  def safe_currency
    currency || Currency.default
  end

  def offer_available?
    offer_status == 'available'
  end

  def inactive_reason
    return 'Deleted' if deleted?
    return 'Not Published' if !published?
    return 'Invalid Manufacturer' if !manufacturer
    return 'Invalid Model' if !model
    'Invalid Price' if !valid_price?
  end

  def price_gbp
    return if poa?
    Currency.convert(price, currency, Currency.default).round
  end

  private

  def valid_manufacturer_model
    if (model_id_changed? || manufacturer_id_changed?) && model && model.manufacturer != manufacturer
      errors.add :model_id, "model [#{model}] should belong to manufacturer [#{manufacturer}]"
    end
  end

  def valid_price
    if published? && !valid_price?
      self.errors.add :price, "can't be blank"
    end
  end

  # featured and reduced attrs are used without solr in some queries
  # so it should be set as true only for live boats
  def valid_featured
    return if deleted?

    [:featured, :recently_reduced].each do |attr_name|
      if send(attr_name) and inactive?
        errors.add attr_name, "can't be set. check manufacturer, model, price and images first"
      end
    end
  end

  def remove_activities
    activities.destroy_all
  end

  def update_leads_price
    if poa_changed? || price_changed? || length_m_changed? || length_f_changed? || currency_id_changed?
      leads.not_deleted.not_invoiced.includes(boat: {user: :deal}).each do |lead|
        lead.update_lead_price!
      end
    end
  end

  def notifiable_favourites_users
    favourites.joins('INNER JOIN user_alerts ON favourites.user_id = user_alerts.user_id')
        .where(user_alerts: {favorites: true}).pluck(:user_id)
  end

  def notifiable_enquiry_users
    leads.not_deleted.joins('INNER JOIN user_alerts ON leads.user_id = user_alerts.user_id')
        .where(user_alerts: {enquiry: true}).pluck(:user_id)
  end

  def notify_changed
    if !id_changed? && price_changed?
      notifiable_favourites_users.each do |user_id|
        UserMailer.boat_status_changed(user_id, id, 'price_changed', 'favourite').deliver_later
      end
      notifiable_enquiry_users.each do |user_id|
        UserMailer.boat_status_changed(user_id, id, 'price_changed', 'enquiry').deliver_later
      end
    end
  end

  def notify_destroyed
    notifiable_favourites_users.each do |user_id|
      UserMailer.boat_status_changed(user_id, id, 'deleted', 'favourite').deliver_later
    end
    notifiable_enquiry_users.each do |user_id|
      UserMailer.boat_status_changed(user_id, id, 'deleted', 'enquiry').deliver_later
    end
  end

  def decrease_counter_cache
    user.decrement!(:boats_count)
  end

  def change_status
    if !deleted? && published? && manufacturer && model && valid_price?
      self.status = 'active'
    else
      self.status = 'inactive'
    end
  end

  def assign_slug
    update_column(:slug, ref_no.downcase)
  end

  def destroy_slave_images
    slave_images.each { |i| i.destroy(:force) }
  end

  def ensure_extra
    create_extra! unless extra
  end

  def ensure_offer_status
    self.offer_status = OFFER_STATUSES.first if offer_status.blank?
  end
end
