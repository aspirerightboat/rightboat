class CreateBrokerInfos < ActiveRecord::Migration
  def up
    create_table :broker_infos do |t|
      t.references :user, index: true
      t.float :lead_rate, default: 1
      t.float :discount, default: 0

      t.datetime :updated_at
    end
  end
end
