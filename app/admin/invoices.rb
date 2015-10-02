ActiveAdmin.register Invoice do
  menu parent: 'Leads'

  config.sort_order = 'id_desc'
  permit_params :user_id, :subtotal, :discount_rate, :discount, :total_ex_vat,
                :vat_rate, :vat, :total

  filter :user, as: :select, collection: -> { User.companies.order(:company_name, :first_name) }

  index do
    column :user
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
      f.input :user, as: :select, collection: -> { User.where(id: f.object.id) }
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

  sidebar 'Tools', only: [:index] do
    link_to('Generate Invoices', {action: :generate_invoices}, method: :post, class: 'button')
  end

  collection_action :generate_invoices, method: :post do
    CreateInvoicesJob.new.perform
    redirect_to({action: :index}, {notice: 'Invoices were generated and report email was sent'})
  end

end
