class Manufacturer < ActiveRecord::Base
  include AdvancedSolrIndex
  include FixSpelling
  include BoatOwner

  extend FriendlyId
  friendly_id :slug_candidates, use: [:slugged, :finders]

  has_many :models, inverse_of: :manufacturer, dependent: :restrict_with_error

  solr_update_association :models, :boats, fields: [:active, :name]
  mount_uploader :logo, AvatarUploader

  validates_presence_of :name
  validates_uniqueness_of :name, allow_blank: true

  scope :active, -> { where("active = ?", true)}

  searchable do
    string :name
    string :name_ngrme, as: :name_ngrme
    boolean :live do |record|
      record.active? && record.boats.count > 0
    end
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
