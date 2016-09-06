class BoatType < ActiveRecord::Base
  include FixSpelling
  include BoatOwner

  extend FriendlyId
  friendly_id :name, use: [:slugged]

  GENERAL_TYPES = %w(power sail other)

  validates_presence_of :name
  validates_uniqueness_of :name, allow_blank: true

  before_validation :set_name_stripped

  def to_s
    name_stripped
  end

  private

  def set_name_stripped
    self.name_stripped = case name.to_s
                         when /power|motor|cruiser/i
                           'power'
                         when /sail/i
                           'sail'
                         else
                           'other'
                         end
  end
end
