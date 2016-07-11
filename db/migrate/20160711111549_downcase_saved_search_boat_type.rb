class DowncaseSavedSearchBoatType < ActiveRecord::Migration
  def up
    SavedSearch.where(boat_type: 'Power').update_all(boat_type: 'power')
    SavedSearch.where(boat_type: 'Sail').update_all(boat_type: 'sail')
  end
end
