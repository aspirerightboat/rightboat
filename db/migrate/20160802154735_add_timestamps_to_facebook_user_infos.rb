class AddTimestampsToFacebookUserInfos < ActiveRecord::Migration
  def up
    add_column :facebook_user_infos, :updated_at, :datetime
    add_column :facebook_user_infos, :created_at, :datetime
    FacebookUserInfo.update_all(created_at: Time.current, updated_at: Time.current)
  end
end
