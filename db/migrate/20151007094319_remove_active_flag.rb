class RemoveActiveFlag < ActiveRecord::Migration
  def change
    remove_column :boat_categories, :active
    remove_column :boat_types, :active
    remove_column :countries, :active
    remove_column :currencies, :active
    remove_column :drive_types, :active
    remove_column :engine_manufacturers, :active
    remove_column :engine_models, :active
    remove_column :fuel_types, :active
    remove_column :manufacturers, :active
    remove_column :models, :active
    remove_column :specifications, :active
    remove_column :vat_rates, :active
    remove_column :mail_subscriptions, :active
    remove_column :mail_subscriptions, :updated_at
    add_column :mail_subscriptions, :deleted_at, :datetime
  end
end
