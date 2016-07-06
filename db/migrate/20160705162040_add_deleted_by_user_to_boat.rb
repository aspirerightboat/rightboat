class AddDeletedByUserToBoat < ActiveRecord::Migration
  def change
    add_column :boats, :deleted_by_user_id, :integer
    add_index :boats, :deleted_by_user_id
  end
end
