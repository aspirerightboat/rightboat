class CreateSavedSearch < ActiveRecord::Migration
  def change
    create_table :saved_searches do |t|
      t.references :user, index: true
      t.integer :year_min, :year_max
      t.decimal :price_min, :price_max
      t.float :length_min, :length_max
      t.string :length_unit
      t.string :manufacturer_model
      t.string :currency
      t.string :ref_no
      t.boolean :paid, :unpaid, :fresh, :used
      t.integer :first_found_boat_id
      t.datetime :created_at
    end
  end
end
