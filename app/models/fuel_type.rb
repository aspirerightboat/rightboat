class FuelType < ActiveRecord::Base
  include SunspotRelation
  include FixSpelling

  has_many :boats, inverse_of: :fuel_type, dependent: :restrict_with_error

  sunspot_related :boats

  validates_presence_of :name
  validates_uniqueness_of :name, allow_blank: true

  scope :active, -> { where active: true }

  searchable do
    string :name do |record|
      record.name_ngrme
    end
    string :name_ngrme, as: :name_ngrme
    boolean :live do |record|
      record.active? && record.boats.count > 0
    end
  end

  def name_stripped
    case name.to_s
      when /petrol|lpg/i
        'Petrol'
      when /diesel/i
        'Diesel'
      else
        'Other'
    end
  end
  alias_method :name_ngrme, :name_stripped

  def to_s
    name
  end

end
