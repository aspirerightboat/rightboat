class Invoice < ApplicationRecord
  has_many :leads
  belongs_to :user

  def display_xero_invoice_number
    "INV-#{xero_invoice_number}" if xero_invoice_number
  end
end
