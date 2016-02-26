class AddHiddenToEnquiries < ActiveRecord::Migration
  def change
    add_column :enquiries, :hidden, :boolean, default: false
  end
end
