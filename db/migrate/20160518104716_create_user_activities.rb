class CreateUserActivities < ActiveRecord::Migration
  def change
    create_table :user_activities do |t|
      t.integer :user_id, default: nil
      t.string :user_email, default: nil
      t.string :kind
      t.integer :boat_id, default: nil
      t.integer :lead_id, default: nil
      t.string :query, default: nil
      t.timestamps
    end
    add_index :user_activities, :user_id
    add_index :user_activities, :user_email
    add_index :user_activities, :boat_id
    add_index :user_activities, :lead_id
  end

end
