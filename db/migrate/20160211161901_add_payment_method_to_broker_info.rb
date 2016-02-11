class AddPaymentMethodToBrokerInfo < ActiveRecord::Migration
  def change
    add_column :broker_infos, :payment_method, :string, default: 'none'
  end
end
