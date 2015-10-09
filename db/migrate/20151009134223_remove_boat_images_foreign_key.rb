class RemoveBoatImagesForeignKey < ActiveRecord::Migration
  def up
    remove_foreign_key :boat_images, :boats
    remove_foreign_key :boat_specifications, :boats
    remove_foreign_key :boat_specifications, :specifications
  end
end
