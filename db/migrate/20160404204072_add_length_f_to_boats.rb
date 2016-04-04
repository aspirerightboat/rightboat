class AddLengthFToBoats < ActiveRecord::Migration
  def up
    add_column :boats, :length_f, :float
  end
end
