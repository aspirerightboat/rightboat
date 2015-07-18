class DriveType < ActiveRecord::Base
  include AdvancedSolrIndex
  include FixSpelling

  has_many :boats, inverse_of: :drive_type, dependent: :restrict_with_error

  solr_update_association :boats

  validates_presence_of :name
  validates_uniqueness_of :name, allow_blank: true

  scope :active, -> { where("active = ?", true)}

end
