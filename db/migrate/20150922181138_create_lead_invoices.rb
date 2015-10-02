class CreateLeadInvoices < ActiveRecord::Migration
  def change
    create_table :invoices do |t|
      t.references :user, index: true
      t.decimal :subtotal
      t.float :discount_rate
      t.decimal :discount
      t.decimal :total_ex_vat
      t.float :vat_rate
      t.decimal :vat
      t.decimal :total

      t.timestamps
    end

    add_column :enquiries, :invoice_id, :integer
    add_index :enquiries, :invoice_id
  end
end
