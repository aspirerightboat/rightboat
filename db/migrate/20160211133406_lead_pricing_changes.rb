class LeadPricingChanges < ActiveRecord::Migration
  def up
    add_column :broker_infos, :lead_min_price, :float
    add_column :broker_infos, :lead_max_price, :float
    rename_column :broker_infos, :lead_rate, :lead_length_rate
    RBConfig.repair
    BrokerInfo.update_all(lead_length_rate: 2, lead_min_price: 5, lead_max_price: 300)
    remove_column :enquiries, :eur_rate
  end
end
