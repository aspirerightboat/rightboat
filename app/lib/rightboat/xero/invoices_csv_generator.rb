module Rightboat
  module Xero
    class InvoicesCsvGenerator

      def self.csv_path
        @csv_path ||= '/invoices.csv'
      end

      def self.csv_file_path
        @csv_fullpath ||= "#{Rails.root}/internal_data#{csv_path}"
      end

      def initialize(invoicing_data, tax_rate_by_type)
        @invoicing_data = invoicing_data
        @tax_rate_by_type = tax_rate_by_type
      end

      def run
        self.class.ensure_csv_dir

        CSV.open(self.class.csv_file_path, 'wb') do |csv|
          csv << ['Contact Name',
                  'Invoice No',
                  'Invoice Date',
                  'Net',
                  'VAT',
                  'Total £',
                  'Total €',
                  'Total $',
                  'STR',
                  'GC',
                  'DEBTOR',
                  'Tax Type',
                  'Currency',
                  'PO Country',
                  'US County',
          ]
          @invoicing_data.each do |i, xi, _leads|
            currency = i.user.deal.currency.name
            payment_method = i.user.broker_info.payment_method
            tax_rate = @tax_rate_by_type[xi.line_items.first.tax_type]
            user_address = i.user.address
            csv << [xi.contact.name, # Contact Name
                    xi.invoice_number, # Invoice No
                    xi.date, # Invoice Date
                    '%.2f' % i.total_ex_vat, # Net
                    '%.2f' % i.vat, # VAT
                    ('%.2f' % i.total if currency == 'GBP'), # Total £
                    ('%.2f' % i.total if currency == 'EUR'), # Total €
                    ('%.2f' % i.total if currency == 'USD'), # Total $
                    ('Y' if payment_method == 'card'), # STR
                    ('Y' if payment_method == 'dd'), # GC
                    ('Y' if payment_method['none']), # DEBTOR
                    tax_rate.name, # Tax Type
                    currency, # Currency
                    user_address.country&.name, # PO Country
                    (user_address.county if user_address.country&.iso == 'US'), # US County
            ]
          end
        end
      end

      def self.ensure_csv_dir
        dir = File.dirname(csv_file_path)
        FileUtils.mkdir(dir) unless Dir.exist?(dir)
      end

    end
  end
end
