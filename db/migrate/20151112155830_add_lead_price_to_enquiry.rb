class AddLeadPriceToEnquiry < ActiveRecord::Migration
  def change
    add_column :enquiries, :lead_price, :decimal

    Enquiry.reset_column_information

    Enquiry.not_deleted.not_invoiced.find_each do |lead|
      lead.update_lead_price
    end
  end
end
