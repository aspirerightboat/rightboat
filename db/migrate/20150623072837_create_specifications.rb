class CreateSpecifications < ActiveRecord::Migration
  def change
    create_table :specifications do |t|
      t.string  :name,        index: true
      t.string  :display_name
      t.integer :position
      t.boolean :active,      index: true, default: false

      t.timestamps null: false
    end
  end
end
