class AddUserCountryIsoToLead < ActiveRecord::Migration
  def change
    add_column :leads, :user_country_iso, :string, limit: 2
  end
end
