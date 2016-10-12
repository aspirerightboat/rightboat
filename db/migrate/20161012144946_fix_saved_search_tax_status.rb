class FixSavedSearchTaxStatus < ActiveRecord::Migration
  def up
    # This migration should be executed on rails < 5

    # is:
    # "--- !ruby/hash:ActionController::Parameters\npaid: 'true'\n"
    # should be:
    # "---\npaid: 'true'\n"

    SavedSearch.where('tax_status LIKE ?', '%ActionController%').each do |ss|
      ss.update_column(:tax_status, ss.tax_status.permit(%w(paid unpaid)).to_h)
    end

    SavedSearch.where('new_used LIKE ?', '%ActionController%').each do |ss|
      ss.update_column(:new_used, ss.new_used.permit(%w(new used)).to_h)
    end
  end
end
