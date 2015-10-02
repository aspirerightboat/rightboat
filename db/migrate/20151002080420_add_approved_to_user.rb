class AddApprovedToUser < ActiveRecord::Migration
  def change
    add_column :users, :email_confirmed, :boolean, default: false
    add_index  :users, :email_confirmed
  end
end
