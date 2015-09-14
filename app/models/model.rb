class Model < ActiveRecord::Base
  include AdvancedSolrIndex
  include FixSpelling
  include BoatOwner

  extend FriendlyId
  friendly_id :slug_candidates, use: [:slugged, :finders]

  belongs_to :manufacturer, inverse_of: :models

  # solr_update_association :boats, fields: [:active, :name, :manufacturer_id]

  validates_presence_of :manufacturer, :name
  validates_uniqueness_of :name, scope: :manufacturer_id

  scope :active, -> { where("active = ?", true)}

  searchable do
    string :name do |model|
      model.full_name
    end
    string :name_ngrme, as: :name_ngrme do |model|
      model.full_name
    end
    integer :manufacturer_id
    boolean :live do |record|
      record.manufacturer.try(&:active?) && record.active? && record.boats.count > 0
    end
  end
  alias_attribute :name_ngrme, :name

  def to_s
    name
  end

  def full_name
    [self.manufacturer, self.name].reject(&:blank?).join(' ')
  end


  private

  def slug_candidates
    [ name, "rb-#{name}" ]
  end

end
