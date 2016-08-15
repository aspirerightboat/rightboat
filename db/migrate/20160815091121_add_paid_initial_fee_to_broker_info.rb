class AddPaidInitialFeeToBrokerInfo < ActiveRecord::Migration
  def change
    add_column :broker_infos, :paid_initial_fee, :boolean, default: false
  end
end
