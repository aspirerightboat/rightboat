class BoatSpecification < ApplicationRecord
  belongs_to :specification, inverse_of: :boat_specifications
  belongs_to :boat

  validates_presence_of :specification

  scope :front, -> { joins(:specification).where('specifications.visible = ?', true) }
  scope :not_blank, -> { where.not(value: [nil, '']) }
  scope :not_url, -> { where.not('value LIKE ?', '%http%') }

  def self.specs_hash
    joins(:specification).pluck('specifications.name, boat_specifications.value').to_h.with_indifferent_access
  end

  def self.custom_specs_hash(names)
    joins(:specification).where(specifications: {name: names}).pluck('specifications.name, boat_specifications.value').to_h
  end

end
