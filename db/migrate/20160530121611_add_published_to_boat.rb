class AddPublishedToBoat < ActiveRecord::Migration
  def up
    add_column :boats, :published, :boolean, default: true
    add_column :boats, :expert_boat, :boolean, default: false
  end

  def down
    remove_column :boats, :rb_boat
  end
end
