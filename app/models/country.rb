class Country < ActiveRecord::Base
  include SunspotRelation
  include FixSpelling

  extend FriendlyId
  friendly_id :name, use: [:slugged, :finders]

  has_many :boats, inverse_of: :country, dependent: :restrict_with_error
  belongs_to :currency, inverse_of: :countries

  sunspot_related :boats

  validates_presence_of :iso, :name
  validates_uniqueness_of :iso, :name, allow_blank: true

  scope :active, -> { where active: true }

  searchable do
    string :name
    string :name_ngrme, as: :name_ngrme
    boolean :live do |record|
      record.active? && record.boats.count > 0
    end
  end
  alias_attribute :name_ngrme, :name

  def to_s
    name
  end
end
