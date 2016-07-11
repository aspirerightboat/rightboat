class BoatType < ActiveRecord::Base
  include FixSpelling
  include BoatOwner

  extend FriendlyId
  friendly_id :name, use: [:slugged]

  GENERAL_TYPES = %w(power sail other)

  validates_presence_of :name
  validates_uniqueness_of :name, allow_blank: true

  def to_s
    name_stripped
  end

  def name_stripped
    case name.to_s
      when /power|motor|cruiser/i
        'power'
      when /sail/i
        'sail'
      else
        'other'
    end
  end
end
