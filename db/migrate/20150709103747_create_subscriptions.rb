class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.string :name
      t.string :description

      t.timestamps null: false
    end
    add_index :subscriptions, :name, unique: true

    create_table :subscriptions_users do |t|
      t.references :user
      t.references :subscription
    end
    add_index :subscriptions_users, [:user_id, :subscription_id], unique: true
  end
end
