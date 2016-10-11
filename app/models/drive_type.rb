class DriveType < ApplicationRecord
  include FixSpelling
  include BoatOwner

  belongs_to :created_by_user, class_name: 'User'

  validates_presence_of :name
  validates_uniqueness_of :name, allow_blank: true

end
