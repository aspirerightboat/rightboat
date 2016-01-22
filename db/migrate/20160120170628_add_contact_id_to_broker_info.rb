class AddContactIdToBrokerInfo < ActiveRecord::Migration
  def change
    add_column :broker_infos, :xero_contact_id, :string
  end
end
