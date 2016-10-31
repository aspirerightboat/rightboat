class AddFieldsToInsurances < ActiveRecord::Migration[5.0]
  def change
    add_column :insurances, :full_name, :string
    add_column :insurances, :contact_number, :string
    add_column :insurances, :email, :string
    add_column :insurances, :craft_year, :integer
    add_column :insurances, :renewal_date, :date
  end
end
