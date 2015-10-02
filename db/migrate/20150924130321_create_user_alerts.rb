class CreateUserAlerts < ActiveRecord::Migration
  def up
    drop_table :subscriptions
    drop_table :subscriptions_users

    create_table :user_alerts do |t|
      t.references :user, index: true
      t.boolean :favorites, default: true
      t.boolean :saved_searches, default: true
      t.boolean :suggestions, default: true
      t.boolean :newsletter, default: true
    end
  end
end
