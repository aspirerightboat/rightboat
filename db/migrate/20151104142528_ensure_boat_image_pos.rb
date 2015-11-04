class EnsureBoatImagePos < ActiveRecord::Migration
  def up
    change_column :boat_images, :position, :integer, default: 0

    BoatImage.where(position: nil).update_all(position: 0)
  end
end
