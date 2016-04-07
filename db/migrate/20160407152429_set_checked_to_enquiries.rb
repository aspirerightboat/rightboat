class SetCheckedToEnquiries < ActiveRecord::Migration
  def change
    change_column_default :user_alerts, :enquiry, true
  end
end
