class CreateRawBoat < ActiveRecord::Migration
  def change
    create_table :raw_boats do |t|
      t.string :name
      t.boolean :new_boat
      t.boolean :poa
      t.string :location
      t.string :geo_location
      t.integer :year_built
      t.decimal :price
      t.float :length_m
      t.integer :boat_type_id
      t.integer :office_id
      t.integer :manufacturer_id
      t.integer :model_id
      t.integer :country_id
      t.integer :currency_id
      t.integer :drive_type_id
      t.integer :engine_manufacturer_id
      t.integer :engine_model_id
      t.integer :vat_rate_id
      t.integer :fuel_type_id
      t.integer :category_id
      t.string :offer_status
      t.float :length_f
      t.string :state

      t.timestamps
    end

    add_column :boats, :raw_boat_id, :integer
    add_index :boats, :raw_boat_id
  end
end
