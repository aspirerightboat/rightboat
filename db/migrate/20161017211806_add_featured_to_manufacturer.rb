class AddFeaturedToManufacturer < ActiveRecord::Migration[5.0]
  def change
    add_column :manufacturers, :featured, :boolean, default: false
  end
end
