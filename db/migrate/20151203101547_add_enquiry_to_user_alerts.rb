class AddEnquiryToUserAlerts< ActiveRecord::Migration
  def change
    add_column :user_alerts, :enquiry, :boolean, default: false
  end
end
