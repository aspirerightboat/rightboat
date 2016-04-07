class CreateMailClicks < ActiveRecord::Migration
  def change
    create_table :mail_clicks do |t|
      t.integer :user_id
      t.string  :url
      t.string  :action_fullname
      t.integer :saved_searches_alert_id

      t.timestamps
    end
  add_index :mail_clicks, :action_fullname
  end
end

