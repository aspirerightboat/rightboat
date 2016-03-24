class BoatType < ActiveRecord::Base
  include FixSpelling
  include BoatOwner

  extend FriendlyId
  friendly_id :name, use: [:slugged]

  GENERAL_TYPES = %w(Power Sail Other)

  validates_presence_of :name
  validates_uniqueness_of :name, allow_blank: true

  def to_s
    name_stripped
  end

  def name_stripped
    case name.to_s
      when /power|motor|cruiser/i
        'Power'
      when /sail/i
        'Sail'
      else
        'Other'
    end
  end
end
