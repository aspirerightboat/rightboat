class OldSlug < ActiveRecord::Base
  belongs_to :sluggable, polymorphic: true
  belongs_to :boat, -> { where(old_slugs: {sluggable_type: 'Boat'}) }, foreign_key: 'sluggable_id'
end