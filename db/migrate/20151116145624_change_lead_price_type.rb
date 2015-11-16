class ChangeLeadPriceType < ActiveRecord::Migration
  def change
    change_column :enquiries, :lead_price, :decimal, precision: 10, scale: 2

    Enquiry.reset_column_information

    Enquiry.find_each do |e|
      e.update_lead_price
    end
  end
end
