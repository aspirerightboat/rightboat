class AddXeroInvoiceNumberToInvoice < ActiveRecord::Migration[5.0]
  def change
    add_column :invoices, :xero_invoice_number, :string
  end
end
