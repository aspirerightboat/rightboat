class OldSlug < ApplicationRecord
  belongs_to :sluggable, polymorphic: true
  belongs_to :boat, foreign_key: 'sluggable_id'
  belongs_to :model, foreign_key: 'sluggable_id'

  scope :boats, -> { where(sluggable_type: 'Boat') }
  scope :models, -> { where(sluggable_type: 'Model') }
end
