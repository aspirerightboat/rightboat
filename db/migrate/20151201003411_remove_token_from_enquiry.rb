class RemoveTokenFromEnquiry < ActiveRecord::Migration
  def up
    remove_column :enquiries, :token
  end
end
