class AddDeletedByUserToBoatImages < ActiveRecord::Migration
  def change
    add_column :boat_images, :deleted_by_user_id, :integer
    add_index :boat_images, :deleted_by_user_id
  end
end
