class AddAccountManagerIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :account_manager_id, :integer
    add_index :users, :account_manager_id
  end
end
