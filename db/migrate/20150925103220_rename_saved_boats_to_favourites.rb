class RenameSavedBoatsToFavourites < ActiveRecord::Migration
  def change
    rename_table :saved_boats, :favourites
  end
end
