class AddTokenToSavedSearchesAlert < ActiveRecord::Migration
  def up
    add_column :saved_searches_alerts, :token, :string
    add_index :saved_searches_alerts, :token

    SavedSearchesAlert.reset_column_information

    SavedSearchesAlert.find_each do |ss_alert|
      ss_alert.send(:assign_token)
      ss_alert.save!
    end
  end
end
