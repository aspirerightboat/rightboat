class VatRate < ActiveRecord::Base
  include FixSpelling
  include SunspotRelation

  has_many :boats, inverse_of: :vat_rate, dependent: :restrict_with_error

  sunspot_related :boats

  validates_presence_of :name
  validates_uniqueness_of :name, allow_blank: true

  scope :active, -> { where active: true }

  def to_s
    name
  end
end
