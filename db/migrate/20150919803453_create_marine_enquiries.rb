class CreateMarineEnquiries < ActiveRecord::Migration
  def change
    create_table :marine_enquiries do |t|
      t.string :title
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :enquiry_type
      t.string :country_code
      t.string :phone
      t.text :comments

      t.timestamps null: false
    end
  end
end
