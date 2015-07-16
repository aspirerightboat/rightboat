class DriveType < ActiveRecord::Base
  include SunspotRelation
  include FixSpelling

  has_many :boats, inverse_of: :drive_type, dependent: :restrict_with_error

  sunspot_related :boats

  validates_presence_of :name
  validates_uniqueness_of :name, allow_blank: true

  scope :active, -> { where("active = ?", true)}

end
