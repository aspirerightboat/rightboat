class AddBrandNewToBoat < ActiveRecord::Migration[5.0]
  def change
    add_column :boats, :brand_new, :boolean, default: false
  end
end
