class CreateBoatTemplate < ActiveRecord::Migration
  def change
    create_table :boat_templates do |t|
      t.boolean :auto_created, default: false
      t.references :manufacturer, index: true
      t.references :model, index: true
      t.integer :year_built
      t.decimal :price, precision: 15, scale: 2, default: 0
      t.float :length_m
      t.references :boat_type, index: true
      t.references :drive_type, index: true
      t.references :engine_manufacturer, index: true
      t.references :engine_model, index: true
      t.references :fuel_type, index: true
      t.text :short_description
      t.text :description
      t.text :from_boats
      t.text :specs

      t.timestamps
    end
  end
end
