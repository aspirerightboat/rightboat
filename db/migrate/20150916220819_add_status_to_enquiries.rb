class AddStatusToEnquiries < ActiveRecord::Migration
  def change
    add_column :enquiries, :status, :string, limit: 32, default: 'pending'
  end
end
