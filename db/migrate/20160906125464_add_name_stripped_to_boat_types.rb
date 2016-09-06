class AddNameStrippedToBoatTypes < ActiveRecord::Migration
  def up
    add_column :boat_types, :name_stripped, :string
    add_index :boat_types, :name_stripped

    BoatType.reset_column_information
    BoatType.find_each { |t| t.save }
  end

  def down
    remove_index :boat_types, :name_stripped
    remove_column :boat_types, :name_stripped
  end
end
