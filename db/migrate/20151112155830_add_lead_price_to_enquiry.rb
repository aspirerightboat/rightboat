class AddLeadPriceToEnquiry < ActiveRecord::Migration
  def change
    add_column :enquiries, :lead_price, :decimal

    # Lead.reset_column_information
    #
    # Lead.not_deleted.not_invoiced.find_each do |lead|
    #   lead.update_lead_price
    # end
  end
end
