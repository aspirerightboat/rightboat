class CreateBrokerIframe < ActiveRecord::Migration
  def change
    create_table :broker_iframes do |t|
      t.references :user, index: true
      t.string :token
      t.boolean :user_boats_only, default: true
      t.text :filters

      t.timestamps
    end
  end
end
