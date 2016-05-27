namespace :xero_invoicer do
  desc 'Create xero invoices from approved leads'
  task process_invoices: :environment do
    Rightboat::XeroInvoicer.new.process_invoices
  end
end
