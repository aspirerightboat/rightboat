class AddCountryCodeToEnquiries < ActiveRecord::Migration
  def change
    add_column :enquiries, :country_code, :string
  end
end
