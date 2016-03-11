class DriveType < ActiveRecord::Base
  include FixSpelling
  include BoatOwner

  validates_presence_of :name
  validates_uniqueness_of :name, allow_blank: true

end
