class RemoveOldSavedSearches < ActiveRecord::Migration
  def up
    SavedSearch.delete_all
  end
end
