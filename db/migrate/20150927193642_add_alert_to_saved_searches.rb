class AddAlertToSavedSearches < ActiveRecord::Migration
  def change
    add_column :saved_searches, :alert, :boolean, default: true
  end
end
