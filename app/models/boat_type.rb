class BoatType < ActiveRecord::Base
  include SunspotRelation
  include FixSpelling

  has_many :boats, inverse_of: :boat_type, dependent: :restrict_with_error

  sunspot_related :boats

  validates_presence_of :name
  validates_uniqueness_of :name, allow_blank: true

  scope :active, -> { where active: true }

  searchable do
    string :name
    string :name_ngrme, as: :name_ngrme
    boolean :live do |record|
      record.active? && record.boats.count > 0
    end
  end
  alias_attribute :name_ngrme, :name

  def to_s
    name
  end

  def name_stripped
    case name.to_s
      when /power|motor|cruiser/i
        'Power'
      when /sail/i
        'Sail'
      else
        'Other'
    end
  end
end
