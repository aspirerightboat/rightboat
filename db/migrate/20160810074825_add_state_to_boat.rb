class AddStateToBoat < ActiveRecord::Migration

  def up
    add_column :boats, :state, :string
  end

end
