class AddLengthUnitToCountry < ActiveRecord::Migration
  def change
    add_column :countries, :length_unit, :string, default: 'm'
    Country.where(iso: ['GB', 'US']).update_all(length_unit: 'ft')
  end
end
