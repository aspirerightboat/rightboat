class AddCompanyWeburlToUsers < ActiveRecord::Migration
  def change
    add_column :users, :company_weburl, :string
  end
end
