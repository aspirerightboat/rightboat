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
      invoice.enquiries.map { |lead| r << link_to(lead.id, admin_lead_path(lead)).html_safe; r << ' ' }
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
    para { link_to 'Generate Invoices', {action: :generate_invoices}, method: :post, class: 'button' }
    para { link_to 'Gen Invoices for user=315', {action: :generate_test_invoices}, method: :post, class: 'button' }
    para { link_to 'Last Generate Invocies Log', {action: :last_log} }
    para { link_to 'Xero Log', {action: :xero_log} }
  end

  controller do
    def scoped_collection
      Invoice.includes(:user, :enquiries)
    end
  end

  collection_action :generate_invoices, method: :post do
    res = CreateInvoicesJob.new.perform
    redirect_to({action: :index}, res ? {notice: 'Invoices were generated and report email was sent'} : {alert: 'Error occurred, view logs'})
  end

  collection_action :generate_test_invoices, method: :post do
    res = CreateInvoicesJob.new.perform(315)
    redirect_to({action: :index}, res ? {notice: 'Invoices were generated and report email was sent'} : {alert: 'Error occurred, view logs'})
  end

  collection_action :last_log do
    html = Arbre::Context.new do
      panel 'Last Generate Invoices Log' do
        file_path = `ls -t log/invoices/* | head -n1`.strip.presence
        if file_path && File.exists?(file_path)
          File.open(file_path, 'r').each_line do |line|
            div do
              line.sub!(/\bbroker_id=(\d+)/) { "broker_id=#{link_to $1, admin_user_path($1)}" }
              line.html_safe
            end
          end
        end
      end
    end
    render html: html.to_s, layout: 'active_admin'
  end

  collection_action :xero_log do
    html = Arbre::Context.new do
      panel 'Last Generate Invoices Log' do
        file_path = 'log/xero.log'
        if file_path && File.exists?(file_path)
          File.open(file_path, 'r').each_line do |line|
            div { line.html_safe }
          end
        end
      end
    end
    render html: html.to_s, layout: 'active_admin'
  end

end
