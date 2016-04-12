class AddSavedSearchesCountToUsers < ActiveRecord::Migration
  def change
    add_column :users, :saved_searches_count, :integer, default: 0
  end
end
