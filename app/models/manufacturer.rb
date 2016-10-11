class Manufacturer < ApplicationRecord
  include FixSpelling
  include BoatOwner

  extend FriendlyId
  friendly_id :slug_candidates, use: [:slugged, :finders]

  has_many :models, inverse_of: :manufacturer, dependent: :restrict_with_error
  has_many :buyer_guides, class_name: 'BuyerGuide', inverse_of: :manufacturer, dependent: :destroy
  has_many :finances
  has_many :insurances
  belongs_to :created_by_user, class_name: 'User'

  mount_uploader :logo, AvatarUploader

  validates_presence_of :name
  validates_uniqueness_of :name, allow_blank: true

  after_save :reindex_boats

  searchable do
    text(:name_full_ngram, as: :name_full_ngram, boost: 2) { |m| m.name }
    text(:name_ngram, as: :name_ngram, boost: 1) { |m| m.name }
    integer :id
    string :name, stored: true

    join :live, target: Boat, type: :boolean, join: {from: :manufacturer_id, to: :id}
  end

  def to_s
    name
  end

  def self.solr_suggest_by_term(term)
    if term.blank?
      makers = Rails.cache.fetch 'top-30-maker-infos', expires_in: 1.day do
        Manufacturer.joins(:boats)
            .group('manufacturers.id, manufacturers.name').order('COUNT(*) DESC')
            .limit(30).pluck('manufacturers.id, manufacturers.name')
            .sort_by(&:second).map { |id, m_name| {id: id, name: m_name} }
      end
      return makers
    end

    search = retryable_solr_search! do
      fulltext term if term.present?
      with :live, true
      order_by :name, :asc
    end

    search.hits.map { |h| {id: h.primary_key, name: h.stored(:name)} }
  end

  def merge_and_destroy!(other_manufacturer)
    models.each { |model| model.move_to_manufacturer(other_manufacturer) }

    misspellings.update_all(source_id: other_manufacturer.id)
    buyer_guides.update_all(manufacturer_id: other_manufacturer.id)
    finances.update_all(manufacturer_id: other_manufacturer.id)
    insurances.update_all(manufacturer_id: other_manufacturer.id)

    reload
    destroy!
  end

  private

  def reindex_boats
    if !id_changed? && name_changed?
      Sunspot.index boats
    end
  end

  def slug_candidates
    [ name, "rb-#{name}" ]
  end

end
