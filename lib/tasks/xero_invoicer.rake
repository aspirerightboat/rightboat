namespace :xero_invoicer do
  desc 'Create xero invoices from approved leads'
  task process_invoices: :environment do
    Rightboat::Xero::Invoicer.new.process_invoices
  end
end
