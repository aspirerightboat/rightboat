class Insurance < ApplicationRecord

  TYPE_OF_COVERS = ['Comprehensive', 'Third Party Only']
  WHERE_KEPTS = ['marina/dry sail', 'mooring/pile']

  belongs_to :user
  belongs_to :manufacturer
  belongs_to :model
  belongs_to :country

  validates_presence_of :user_id, :manufacturer_id, :model_id
  validates_numericality_of :craft_year, only_integer: true
  validates_numericality_of :total_value, allow_blank: true
end
