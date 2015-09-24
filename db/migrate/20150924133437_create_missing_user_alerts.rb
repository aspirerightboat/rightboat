class CreateMissingUserAlerts < ActiveRecord::Migration
  def up
    UserAlert.create(User.pluck(:id).map { |user_id| {user_id: user_id} })
  end
end
