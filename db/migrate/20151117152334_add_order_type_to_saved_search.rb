class AddOrderTypeToSavedSearch < ActiveRecord::Migration
  def change
    add_column :saved_searches, :order, :string
  end
end
