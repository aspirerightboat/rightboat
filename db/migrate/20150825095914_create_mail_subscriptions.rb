class CreateMailSubscriptions < ActiveRecord::Migration
  def change
    create_table :mail_subscriptions do |t|
      t.string :email
      t.boolean :active

      t.timestamps null: false
    end
  end
end
