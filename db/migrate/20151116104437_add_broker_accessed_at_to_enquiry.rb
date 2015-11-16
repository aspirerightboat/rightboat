class AddBrokerAccessedAtToEnquiry < ActiveRecord::Migration
  def change
    add_column :enquiries, :broker_accessed_at, :datetime
    add_column :enquiries, :accessed_by_broker_id, :integer
    add_index :enquiries, :accessed_by_broker_id
  end
end
