class Boat < ActiveRecord::Base
  enum status: [:active, :inactive]
  SELL_REQUEST_TYPES = ['Valuation Request', 'Sell my own Boat', 'Pre-Sale Survey Enquiry']
  OFFER_STATUSES = %w(available under_offer sold)
  VOLUME_UNITS = %w(gallons litres)
  WEIGHT_UNITS = %w(kgs lbs tonnes)

  attr_accessor :tax_paid, :sell_request_type, :accept_toc, :agree_privacy_policy

  searchable do
    text :ref_no,               boost: 5
    text :name,                 boost: 4
    text :manufacturer_model,   boost: 3
    text :manufacturer,         boost: 3
    text :model,                boost: 3
    text :country,              boost: 2
    text :fuel_type,            boost: 2
    text :boat_type,            boost: 2
    text :engine_manufacturer,  boost: 1
    text :engine_model,         boost: 1
    text :drive_type,           boost: 1
    text :description,          boost: 0.5
    string :ref_no
    string :manufacturer_model
    string :manufacturer
    string :model
    integer :user_id
    integer :manufacturer_id
    integer :model_id
    string :fuel_type do |boat|
      boat.fuel_type.try(:name_stripped)
    end
    integer :category_id
    string :boat_type do |boat|
      boat.boat_type.try(:name_stripped)
    end
    integer :drive_type_id
    integer :country_id
    integer :boat_type_id
    integer :year do |boat|
      boat.year_built
    end
    float :price do |boat|
      # TODO: make confirm about poa price filter
      boat.poa? ? 0 : Currency.convert(boat.price, boat.safe_currency, Currency.default)
    end
    float :length_m
    boolean :new_boat
    boolean :tax_paid do |boat|
      boat.tax_paid?
    end
    boolean :live do |boat|
      boat.active?
    end
    time :created_at
  end

  before_validation :change_status
  before_destroy :remove_activities, :decrease_counter_cache
  after_save :update_leads_price
  after_save :notify_changed
  before_destroy :notify_destroyed # this callback should be before "has_many .., dependent: :destroy" associations
  after_create :assign_slug

  has_many :favourites, dependent: :delete_all
  has_many :enquiries
  has_many :boat_specifications
  has_many :boat_images, -> { order(:position, :id) }, dependent: :destroy
  has_one :primary_image, -> { not_deleted.order(:position, :id) }, class_name: 'BoatImage'
  has_many :slave_images, -> { not_deleted.order(:position, :id).offset(1) }, class_name: 'BoatImage'
  belongs_to :user
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

  validates_presence_of :manufacturer, :model
  validate :valid_manufacturer_model
  validate :valid_price
  validate :valid_featured
  validate :valid_terms

  accepts_nested_attributes_for :boat_specifications, reject_if: 'value.blank?'
  accepts_nested_attributes_for :boat_images, reject_if: :all_blank

  scope :featured, -> { where(featured: true) }
  scope :reduced, -> { where(recently_reduced: true) }
  scope :recently_reduced, -> { reduced.limit(3) }

  delegate :tax_paid?, to: :vat_rate, allow_nil: true

  def self.boat_view_includes; includes(:manufacturer, :currency, :primary_image, :model, :vat_rate) end

  def to_param; slug end

  def similar_options(required_currency = nil, length_unit = nil)
    options = {
        exclude_ref_no: ref_no,
        boat_type:  boat_type.try(:name_stripped),
        length_unit: length_unit ||= 'm'
    }

    if !poa?
      required_price = required_currency ? Currency.convert(price, safe_currency, required_currency) : price
      options[:currency] = currency.try(:name)
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

  def manufacturer_model
    return manufacturer.to_s if !model || model.name == 'Unknown'
    [manufacturer.to_s, model.to_s].reject(&:blank?).join(' ')
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
    [location, country.try(:name)].reject(&:blank?).join(', ')
  end

  def length_ft
    if length_f
      length_f.round(2)
    elsif length_m
      length_m.m_to_ft.round(2)
    end
  end

  def geocoded?
    return false if geo_location.blank? || country_id.nil?
    _l, _, _c = geo_location.rpartition(',')
    _l == location.to_s.downcase
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

  private

  def valid_manufacturer_model
    if (model_id_changed? || manufacturer_id_changed?) && model && model.manufacturer != manufacturer
      errors.add :model_id, "[#{model}] should belongs to manufacturer[#{manufacturer}]"
    end
  end

  def valid_price
    unless valid_price?
      self.errors.add :price, 'can\'t be blank'
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

  def valid_terms
    if accept_toc && accept_toc != '1'
      errors.add :base, 'You should accept Rightboat terms and conditions.'
    end

    if agree_privacy_policy && agree_privacy_policy != '1'
      errors.add :base, 'You should agree Rightboat private advert pricing policy.'
    end
  end

  def update_leads_price
    if poa_changed? || price_changed? || length_m_changed?
      enquiries.not_deleted.not_invoiced.each do |lead|
        lead.update_lead_price
      end
    end
  end

  def notifiable_favourites_users
    favourites.joins('INNER JOIN user_alerts ON favourites.user_id = user_alerts.user_id')
        .where(user_alerts: {favorites: true}).pluck(:user_id)
  end

  def notifiable_enquiry_users
    enquiries.not_deleted.joins('INNER JOIN user_alerts ON enquiries.user_id = user_alerts.user_id')
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
    if !deleted? && manufacturer && model && valid_price? && manufacturer.regular?
      self.status = 'active'
    else
      self.status = 'inactive'
    end
  end

  def assign_slug
    update_column(:slug, ref_no.downcase)
  end
end