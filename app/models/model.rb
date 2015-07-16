class Model < ActiveRecord::Base
  include SunspotRelation
  include FixSpelling

  extend FriendlyId
  friendly_id :name, use: [:slugged, :finders]

  has_many :boats, inverse_of: :model, dependent: :restrict_with_error

  belongs_to :manufacturer, inverse_of: :models

  sunspot_related :boats

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
      record.active? && record.boats.count > 0
    end
  end
  alias_attribute :name_ngrme, :name

  def to_s
    name
  end

  def full_name
    [self.manufacturer, self.name].reject(&:blank?).join(' ')
  end
end
