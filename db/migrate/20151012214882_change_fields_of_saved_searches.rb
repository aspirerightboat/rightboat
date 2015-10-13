class ChangeFieldsOfSavedSearches < ActiveRecord::Migration
  def change
    add_column :saved_searches, :q, :string
    add_column :saved_searches, :boat_type, :string
    add_column :saved_searches, :country, :text
    add_column :saved_searches, :tax_status, :string
    add_column :saved_searches, :new_used, :string
    add_column :saved_searches, :category, :string
    remove_column :saved_searches, :paid, :boolean
    remove_column :saved_searches, :unpaid, :boolean
    remove_column :saved_searches, :fresh, :boolean
    remove_column :saved_searches, :used, :boolean
  end
end
