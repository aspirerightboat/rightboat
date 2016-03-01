class AddStatusToBoats < ActiveRecord::Migration
  def change
    add_column :boats, :status, :integer, default: 0
  end
end
