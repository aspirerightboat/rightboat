class Specification < ApplicationRecord
  include FixSpelling

  has_many :boat_specifications, inverse_of: :specification, dependent: :restrict_with_error
  has_many :boats, through: :boat_specifications

  validates_presence_of :name, :display_name
  validates_uniqueness_of :name, allow_blank: true

  scope :front, -> { where(visible: true) }

  def to_s
    display_name
  end

  def self.rename(from, to)
    if (from_spec = Specification.where(name: from).first)
      if (to_spec = Specification.where(name: to).first)
        from_spec.boat_specifications.update_all(specification_id: to_spec.id)
        from_spec.destroy
      else
        from_spec.update_attribute(:name, to)
      end
    end
  end

end
