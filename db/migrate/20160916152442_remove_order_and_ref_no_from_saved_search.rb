class RemoveOrderAndRefNoFromSavedSearch < ActiveRecord::Migration
  def change
    remove_column :saved_searches, :ref_no
    remove_column :saved_searches, :order
  end
end
