class AddBrokerToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :broker, :string
  end
end
