class BoatCategory < ActiveRecord::Base
  include FixSpelling

  has_many :boats, foreign_key: :category_id, dependent: :restrict_with_error

  validates_presence_of :name
  validates_uniqueness_of :name, allow_blank: true

  def to_s
    name
  end

end
