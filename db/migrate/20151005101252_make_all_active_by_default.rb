class MakeAllActiveByDefault < ActiveRecord::Migration
  def change
    change_column :boat_categories, :active, :boolean, default: true
    change_column :boat_types, :active, :boolean, default: true
    change_column :countries, :active, :boolean, default: true
    change_column :currencies, :active, :boolean, default: true
    change_column :drive_types, :active, :boolean, default: true
    change_column :engine_manufacturers, :active, :boolean, default: true
    change_column :engine_models, :active, :boolean, default: true
    change_column :fuel_types, :active, :boolean, default: true
    change_column :imports, :active, :boolean, default: true
    change_column :mail_subscriptions, :active, :boolean, default: true
    change_column :manufacturers, :active, :boolean, default: true
    change_column :models, :active, :boolean, default: true
    change_column :specifications, :active, :boolean, default: true
    change_column :vat_rates, :active, :boolean, default: true
  end
end
