class AddSavedSearchAlertToEnquiries < ActiveRecord::Migration
  def change
    add_column :enquiries, :saved_searches_alert_id, :integer, default: :null
  end
end
