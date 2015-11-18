class ChangeBoatPrice < ActiveRecord::Migration
  def change
    change_column :boats, :price, :decimal, precision: 15, scale: 2
  end
end
