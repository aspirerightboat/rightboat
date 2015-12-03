class Boat < ActiveRecord::Base
  include AdvancedSolrIndex

  extend FriendlyId
  friendly_id :slug_candidates, use: [:slugged, :finders]

  SELL_REQUEST_TYPES = ['Valuation Request', 'Sell my own Boat', 'Pre-Sale Survey Enquiry']

  attr_accessor :tax_paid, :sell_request_type, :accept_toc, :agree_privacy_policy

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
      boat.fuel_type.try(:name_stripped)
    end
    integer :category_id
    string :boat_type do |boat|
      boat.boat_type.try(:name_stripped)
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

  before_destroy :remove_activities
  after_save :update_leads_price
  after_save :notify_changed
  before_destroy :notify_destroyed # this callback should be before "has_many .., dependent: :destroy" associations

  has_many :favourites, dependent: :delete_all
  has_many :enquiries, dependent: :destroy
  has_many :boat_specifications, dependent: :delete_all
  has_many :boat_images, -> { not_deleted }, dependent: :destroy
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

  def self.boat_view_includes; includes(:manufacturer, :currency, :primary_image, :model, :vat_rate) end

  def similar_options(required_currency = nil)
    required_price = required_currency ? Currency.convert(price, currency, required_currency) : price

    options = {
        exclude_ref_no: ref_no,
        currency:   currency.try(:name),
        price_min:  (required_price * 0.8).to_i,
        price_max:  (required_price * 1.2).to_i,
        boat_type:  boat_type.try(:name_stripped),
        category:   [category_id].compact
    }

    if (length = length_m)
      options = options.merge(
          length_min: (length * 80).round.to_f / 100,
          length_max: (length * 120).round.to_f / 100
      )
    end

    options
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

  def full_location
    [location, country.try(:name)].reject(&:blank?).join(', ')
  end

  def length_ft
    length_m.m_to_ft.round(2) if length_m
  end

  def live?
    !deleted? && manufacturer && model && valid_price?
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
end