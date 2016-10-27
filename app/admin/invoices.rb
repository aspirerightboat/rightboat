ActiveAdmin.register Invoice do
  menu parent: 'Leads'

  config.sort_order = 'users.first_name_asc_and_users.last_name_asc_and_invoices.created_at_desc'
  permit_params :user_id, :subtotal, :discount_rate, :discount, :total_ex_vat,
                :vat_rate, :vat, :total

  filter :user, as: :select, collection: -> { User.companies.order(:company_name, :first_name) }

  index do
    column :id
    column :user, :user, sortable: 'users.first_name'
    column :subtotal
    column :discount
    column :total_ex_vat
    column :vat
    column :total
    column :leads do |invoice|
      r = ''.html_safe
      invoice.leads.map { |lead| r << link_to(lead.id, admin_lead_path(lead)).html_safe; r << ' ' }
      r
    end
    actions
  end

  form do |f|
    f.inputs do
      f.input :user
      f.input :subtotal
      f.input :discount_rate
      f.input :discount
      f.input :total_ex_vat
      f.input :vat_rate
      f.input :vat
      f.input :total
    end

    f.actions
  end

  sidebar 'Tools', only: [:index, :last_log, :xero_log] do
    para { link_to 'Generate Invoices Dry Run', {action: :generate_invoices_dry_run}, method: :post, class: 'button', data: {disable_with: 'Working...'} }
    para { link_to 'Generate Invoices', {action: :generate_invoices}, method: :post, class: 'button', data: {disable_with: 'Working...'} }
    para { link_to 'Last Generate Invocies Log', {action: :last_log} }
    para { link_to 'Xero Log', {action: :xero_log} }

    invoices_csv_path = Rightboat::Xero::InvoicesCsvGenerator.csv_file_path
    if File.exist?(invoices_csv_path)
      para {
        div {
          span { link_to 'Download Invoices CSV', action: :invoices_csv }
          span { " (#{link_to 'View', action: :view_invoices_csv})".html_safe }
        }
        div { "Created at: <b>#{File.mtime(invoices_csv_path)}</b>".html_safe }
      }
    end
  end

  controller do
    def scoped_collection
      Invoice.includes(:user, :leads)
    end
  end

  collection_action :generate_invoices, method: :post do
    res = Rightboat::Xero::Invoicer.new.process_invoices
    redirect_to({action: :index}, res ? {notice: 'Invoices were generated'} : {alert: 'Error occurred, view logs'})
  end

  collection_action :generate_invoices_dry_run, method: :post do
    res = Rightboat::Xero::Invoicer.new.process_invoices(dry_run: true)
    redirect_to({action: :index}, res ? {notice: 'invoices.csv was generated'} : {alert: 'Error occurred, view logs'})
  end

  collection_action :invoices_csv do
    send_file Rightboat::Xero::InvoicesCsvGenerator.csv_file_path, filename: "invoices-#{Time.current.to_date.to_s(:db)}.csv"
  end

  collection_action :view_invoices_csv do
    @page_title = 'invoices.csv'
  end
  collection_action :last_log
  collection_action :xero_log

end
