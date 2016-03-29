class OldSlug < ActiveRecord::Base
  belongs_to :sluggable, polymorphic: true
  belongs_to :boat, foreign_key: 'sluggable_id'

  scope :boats, -> { where(sluggable_type: 'Boat') }
end