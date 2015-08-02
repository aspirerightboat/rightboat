class CreateBoatCategories < ActiveRecord::Migration
  def change
    create_table :boat_categories do |t|
      t.string :name,     index: true
      t.boolean :active,  index: true, default: false

      t.timestamps null: false
    end

    add_column :boats, :category_id, :integer, index: true, foreign_key: true
  end
end
