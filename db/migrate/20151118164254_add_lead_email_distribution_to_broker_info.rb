class AddLeadEmailDistributionToBrokerInfo < ActiveRecord::Migration
  def change
    add_column :broker_infos, :lead_email_distribution, :string, default: 'user_and_office'
    remove_column :broker_infos, :copy_to_head_office
  end
end
