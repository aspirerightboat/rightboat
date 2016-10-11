class BoatClassGroup < ApplicationRecord

  belongs_to :boat
  belongs_to :class_code, class_name: 'BoatClassCode'

  validates_presence_of :class_code
end
