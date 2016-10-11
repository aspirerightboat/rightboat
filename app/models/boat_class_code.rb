class BoatClassCode < ApplicationRecord

  has_many :class_groups, class_name: 'BoatClassGroup'

  validates :name, presence: true, uniqueness: true, length: { maximum: 255 }
end
