class Model < ActiveRecord::Base
  include FixSpelling
  include BoatOwner

  extend FriendlyId
  friendly_id :slug_candidates, use: [:slugged, :finders]

  belongs_to :manufacturer, inverse_of: :models
  has_many :buyer_guides
  has_many :finances
  has_many :insurances

  validates_presence_of :manufacturer, :name
  validates_uniqueness_of :name, scope: :manufacturer_id

  after_save :reindex_boats

  searchable do
    text(:name_full_ngram, as: :name_full_ngram, boost: 2) { |m| m.name }
    text(:name_ngram, as: :name_ngram, boost: 1) { |m| m.name }
    integer :id
    integer :manufacturer_id
    string :name, stored: true

    join :live, target: Boat, type: :boolean, join: {from: :model_id, to: :id}
  end

  def to_s
    name
  end

  def name_with_manufacturer
    "#{manufacturer} #{name}".strip
  end

  def merge_and_destroy!(other_model)
    raise ArgumentError.new if manufacturer_id != other_model.manufacturer_id

    misspellings.update_all(source_id: other_model.id)
    boats.update_all(model_id: other_model.id)
    buyer_guides.update_all(model_id: other_model.id)
    finances.update_all(model_id: other_model.id)
    insurances.update_all(model_id: other_model.id)

    reload
    destroy!
  end

  def self.solr_suggest_names(term, manufacturer_names = nil)
    manufacturer_ids = (Manufacturer.where(name: manufacturer_names).pluck(:id) if manufacturer_names.present?)

    search = solr_search do
      fulltext term if term.present?
      with :live, true
      any_of { manufacturer_ids.each { |m_id| with :manufacturer_id, m_id } } if manufacturer_ids.present?
      order_by :name, :asc
    end

    search.hits.sort_by(&:score).reverse!.map { |h| h.stored(:name) }
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
