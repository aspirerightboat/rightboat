class AddFieldsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :source, :string
    add_column :users, :broker_ids, :text
    add_column :users, :contact1, :string
    add_column :users, :contact2, :string
  end
end
