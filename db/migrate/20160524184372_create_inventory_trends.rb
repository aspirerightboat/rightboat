class CreateInventoryTrends < ActiveRecord::Migration
  def change
    create_table :inventory_trends do |t|
      t.integer :total_boats
      t.integer :power_boats
      t.integer :sail_boats
      t.integer :not_power_or_sail
      t.datetime :created_at
    end
  end
end
