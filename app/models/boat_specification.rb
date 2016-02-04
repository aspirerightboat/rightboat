class BoatSpecification < ActiveRecord::Base
  belongs_to :specification, inverse_of: :boat_specifications
  belongs_to :boat

  validates_presence_of :specification

  scope :front, -> { joins(:specification).where('specifications.visible = ?', true) }
  scope :not_blank, -> { where.not(value: [nil, '']) }
  scope :not_url, -> { where.not('value LIKE ?', '%http%') }

  def self.visible_ordered_specs
    joins(:specification).where('specifications.visible = ?', true).order('specifications.position')
        .pluck('specifications.display_name, boat_specifications.value')
  end

  def self.specs_hash
    joins(:specification).pluck('specifications.name, boat_specifications.value').to_h
  end

  def self.custom_specs_hash(names)
    joins(:specification).where(specifications: {name: names}).pluck('specifications.name, boat_specifications.value').to_h
  end

end
