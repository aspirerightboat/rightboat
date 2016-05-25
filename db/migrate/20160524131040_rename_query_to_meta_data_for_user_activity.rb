class RenameQueryToMetaDataForUserActivity < ActiveRecord::Migration
  def change
    rename_column :user_activities, :query, :meta_data
    change_column :user_activities, :meta_data, :text
  end
end
