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

end
