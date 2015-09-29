class AddDimensionsToBoatImages < ActiveRecord::Migration
  def change
    add_column :boat_images, :width, :integer
    add_column :boat_images, :height, :integer
  end
end
