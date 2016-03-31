class CreateSavedSearchesAlerts < ActiveRecord::Migration
  def change
    create_table :saved_searches_alerts do |t|
      t.string  :saved_search_ids
      t.integer  :user_id
      t.datetime :opened_at, default: nil

      t.timestamps
    end
  end
end
