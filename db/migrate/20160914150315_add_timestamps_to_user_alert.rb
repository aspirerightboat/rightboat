class AddTimestampsToUserAlert < ActiveRecord::Migration
  def change
    add_column :user_alerts, :updated_at, :datetime
    add_column :user_alerts, :created_at, :datetime
  end
end
