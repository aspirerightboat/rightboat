class AddSlugToBoatType < ActiveRecord::Migration
  def change
    add_column :boat_types, :slug, :string

    BoatType.reset_column_information

    BoatType.all.each do |bt|
      bt.slug = nil
      bt.save!
    end
  end
end
