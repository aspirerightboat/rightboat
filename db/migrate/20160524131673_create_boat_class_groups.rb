class CreateBoatClassGroups < ActiveRecord::Migration
  def change
    create_table :boat_class_groups do |t|
      t.integer :boat_id
      t.integer :class_code_id
      t.boolean :primary, default: false
      t.datetime :deleted_at
    end

    add_index :boat_class_groups, :boat_id
    add_index :boat_class_groups, :class_code_id
  end
end
