class AddLayoutToBoatImage < ActiveRecord::Migration[5.0]
  def change
    add_column :boat_images, :kind, :integer, default: 0
    add_column :boat_images, :layout_image_id, :integer
    add_column :boat_images, :layout_mark_info, :string
  end
end
