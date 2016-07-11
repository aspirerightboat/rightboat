class FuelType < ActiveRecord::Base
  include FixSpelling
  include BoatOwner

  belongs_to :created_by_user, class_name: 'User'

  validates_presence_of :name
  validates_uniqueness_of :name, allow_blank: true

  def name_stripped
    case name.to_s
      when /petrol|lpg/i
        'petrol'
      when /diesel/i
        'diesel'
      else
        'other'
    end
  end

  def to_s
    name
  end

end
