class AddShortDescriptionToBoat < ActiveRecord::Migration
  def up
    add_column :boats, :short_description, :text

    Boat.reset_column_information

    Boat.not_deleted.includes(:import).find_each do |boat|
      source_boat = Rightboat::Imports::SourceBoat.new
      source_boat.import = boat.import
      description = source_boat.send(:cleanup_description, boat.description)
      short_description = source_boat.send(:cleanup_short_description, description)
      boat.update_columns(short_description: short_description, description: description)
    end
  end
end
