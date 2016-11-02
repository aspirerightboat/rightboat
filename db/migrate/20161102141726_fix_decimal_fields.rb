class FixDecimalFields < ActiveRecord::Migration[5.0]
  def change
    change_column :invoices, :subtotal, :decimal, precision: 15, scale: 2
    change_column :invoices, :discount, :decimal, precision: 15, scale: 2
    change_column :invoices, :total_ex_vat, :decimal, precision: 15, scale: 2
    change_column :invoices, :vat, :decimal, precision: 15, scale: 2
    change_column :invoices, :total, :decimal, precision: 15, scale: 2
    change_column :leads, :lead_price, :decimal, precision: 15, scale: 2
    change_column :raw_boats, :price, :decimal, precision: 15, scale: 2
    change_column :saved_searches, :price_min, :decimal, precision: 15, scale: 2
    change_column :saved_searches, :price_max, :decimal, precision: 15, scale: 2
  end
end
