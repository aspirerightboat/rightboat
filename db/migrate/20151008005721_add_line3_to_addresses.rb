class AddLine3ToAddresses < ActiveRecord::Migration
  def change
    add_column :addresses, :line3, :string
  end
end
