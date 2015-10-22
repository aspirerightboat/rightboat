class Specification < ActiveRecord::Base
  include FixSpelling

  has_many :boat_specifications, inverse_of: :specification, dependent: :restrict_with_error
  has_many :boats, through: :boat_specifications

  validates_presence_of :name, :display_name
  validates_uniqueness_of :name, allow_blank: true

  scope :front, -> { where(visible: true) }

  def to_s
    display_name
  end

  def self.visible_ordered_boat_specs(boat)
    joins('LEFT JOIN boat_specifications ON specifications.id = boat_specifications.specification_id')
        .where('specifications.visible = ?', true).order('specifications.position')
        .where('boat_specifications.boat_id = ?', boat.id)
        .pluck('specifications.display_name, boat_specifications.value')
  end

end
