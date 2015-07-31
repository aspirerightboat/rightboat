class AddPositionToCurrencies < ActiveRecord::Migration
  def change
    add_column :currencies, :position, :integer, index: true
  end
end
