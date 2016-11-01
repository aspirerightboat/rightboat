class AddGeoGuessedFromToBoat < ActiveRecord::Migration[5.0]
  def change
    add_column :boats, :geo_guessed_from, :string
  end
end
