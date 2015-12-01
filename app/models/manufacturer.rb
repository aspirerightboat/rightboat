class Manufacturer < ActiveRecord::Base
  include AdvancedSolrIndex
  include FixSpelling
  include BoatOwner

  extend FriendlyId
  friendly_id :slug_candidates, use: [:slugged, :finders]

  has_many :models, inverse_of: :manufacturer, dependent: :restrict_with_error
  has_many :buyer_guides, class_name: 'BuyerGuide', inverse_of: :manufacturer, dependent: :destroy

  # solr_update_association :models, :boats, fields: [:active, :name]
  mount_uploader :logo, AvatarUploader

  validates_presence_of :name
  validates_uniqueness_of :name, allow_blank: true

  searchable do
    text :name, boost: 2
    text :name_ngrme, as: :name_ngrme, boost: 2
  end
  alias_attribute :name_ngrme, :name

  def to_s
    name.gsub(/&amp;/i, '&')
  end

  private
  def slug_candidates
    [ name, "rb-#{name}" ]
  end

end
