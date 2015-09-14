class AddDeletedAtToBoatDependents < ActiveRecord::Migration
  def change
    add_column :boat_specifications, :deleted_at, :datetime
    add_column :boat_images, :deleted_at, :datetime
  end
end
