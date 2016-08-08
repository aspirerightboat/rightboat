class Model < ActiveRecord::Base
  include FixSpelling
  include BoatOwner

  belongs_to :manufacturer, inverse_of: :models
  has_many :buyer_guides
  has_many :finances
  has_many :insurances
  belongs_to :created_by_user, class_name: 'User'

  validates_presence_of :manufacturer, :name
  validates_uniqueness_of :name, scope: :manufacturer_id

  after_save :reindex_boats
  after_create :regenerate_slug

  searchable do
    text(:name_full_ngram, as: :name_full_ngram, boost: 2) { |m| m.name }
    text(:name_ngram, as: :name_ngram, boost: 1) { |m| m.name }
    integer :id
    integer :manufacturer_id
    string :name, stored: true

    join :live, target: Boat, type: :boolean, join: {from: :model_id, to: :id}
  end

  def to_param; slug end

  def to_s
    name
  end

  def name_with_manufacturer
    "#{manufacturer} #{name}".strip
  end

  def merge_and_destroy!(other_model, other_manufacturer = nil)
    boats.each do |b|
      upd_hash = {model: other_model}
      upd_hash[:manufacturer] = other_manufacturer if other_manufacturer
      b.update!(upd_hash)
    end
    misspellings.update_all(source_id: other_model.id)
    buyer_guides.update_all(model_id: other_model.id)
    finances.update_all(model_id: other_model.id)
    insurances.update_all(model_id: other_model.id)

    reload
    destroy!
  end

  def move_to_manufacturer(other_manufacturer)
    if (other_model = other_manufacturer.models.where(name: name).first)
      merge_and_destroy!(other_model, other_manufacturer)
    else
      transaction do
        update!(manufacturer: other_manufacturer)
        boats.each { |b| b.update!(manufacturer: other_manufacturer) }
      end
    end
  end

  def self.solr_suggest_by_term(term, manufacturer_ids = nil)
    if term.blank? && manufacturer_ids&.one?
      maker_id = manufacturer_ids.first
      models = Rails.cache.fetch "top-30-#{maker_id}-model-infos", expires_in: 1.day do
        Model.joins(:boats).where('models.manufacturer_id = ?', maker_id)
            .group('models.id, models.name').order('COUNT(*) DESC')
            .limit(30).pluck('models.id, models.name')
      end
      return models.sort_by(&:second).map { |id, m_name| {id: id, name: m_name} }
    end

    search = retryable_solr_search! do
      fulltext term if term.present?
      with :live, true
      any_of { manufacturer_ids.each { |m_id| with :manufacturer_id, m_id } } if manufacturer_ids.present?
      order_by :name, :asc
    end

    search.hits.map { |h| {id: h.primary_key, name: h.stored(:name)} }
  end

  def prepend_name!(prepend_part)
    if !name.start_with?(prepend_part)
      new_name = name == 'Unknown' ? prepend_part : "#{prepend_part} #{name}"
      rename!(new_name)
    end
  end

  def rename!(new_name)
    if (other_model = manufacturer.models.where(name: new_name).first)
      merge_and_destroy!(other_model)
    else
      update!(name: new_name)
      regenerate_slug
    end
  end

  def self.model_group_from_name(model_name)
    model_name = model_name.strip
    if model_name =~ /\A\d/
      model_name.match(/\A([^ ]+)/)[1]
    else
      model_name.match(/\A([^ ]+(?: \D[^ ]*)*)/)[1]
    end
  end

  private

  def reindex_boats
    if !id_changed? && (name_changed? || manufacturer_id_changed?)
      Sunspot.index boats
    end
  end

  def regenerate_slug
    new_slug = name.to_slug
    new_slug = name.to_verbose_slug if Model.where(slug: new_slug, manufacturer_id: manufacturer_id).where.not(id: id).exists?

    OldSlug.find_or_create_by(sluggable_type: 'Model', sluggable_id: id, slug: slug) if slug && new_slug != slug

    update_column(:slug, new_slug) if new_slug != slug
  end

end
