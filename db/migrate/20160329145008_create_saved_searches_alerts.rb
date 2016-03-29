class CreateSavedSearchesAlerts < ActiveRecord::Migration
  def change
    create_table :saved_searches_alerts do |t|
      t.integer  :saved_search_id
      t.integer  :alert_pointer_at_start
      t.integer  :alert_pointer_at_end
      t.integer  :user_id
      t.datetime :opened_at, default: nil

      t.timestamps
    end
  end
end
