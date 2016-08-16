class AddNameToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :name, :string
  end
end
