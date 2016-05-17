class RenameEnquiryToLead < ActiveRecord::Migration
  def change
    rename_table :enquiries, :leads
  end
end
