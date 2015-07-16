class BoatSpecification < ActiveRecord::Base
  belongs_to :specification, inverse_of: :boat_specifications
  belongs_to :boat

  validates_presence_of :specification, :boat, :value

  scope :active, -> {
    joins(:specification).where('specifications.active = ?', true)
  }

end
