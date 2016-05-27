namespace :xero_invoicer do
  desc 'Create xero invoices from approved leads'
  task :process_invoices do
    Rightboat::XeroInvoicer.new.process_invoices
  end
end
