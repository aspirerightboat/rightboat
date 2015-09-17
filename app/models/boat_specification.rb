class BoatSpecification < ActiveRecord::Base
  belongs_to :specification, inverse_of: :boat_specifications
  belongs_to :boat

  validates_presence_of :specification, :boat_id, :value

  scope :active, -> {
    joins(:specification).where('specifications.active = ?', true)
  }
  scope :front, -> {
    joins(:specification).where('specifications.visible = ?', true)
  }

  default_scope -> { joins(:specification).order('specifications.position') }

end
