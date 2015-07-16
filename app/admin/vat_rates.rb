ActiveAdmin.register VatRate do
  include SpellFixable

  menu parent: "Boats", label: "VAT Rates"

  permit_params :name, :active

  filter :name
  filter :active, as: :boolean

  index do
    column :name
    column "# Boats" do |r|
      r.boats.count
    end
    column "# Misspellings" do |r|
      link_to "#{r.misspellings.count} (Manage)", [:admin, r, :misspellings]
    end
    column :active do |r|
      r.active? ? status_tag('Active', :ok) : status_tag('Inactive', :error)
    end
    actions do |record|
      if record.active?
        item "Disable", [:disable, :admin, record], method: :post, class: 'job-action job-action-warning'
      else
        item "Activate", [:active, :admin, record], method: :post, class: 'job-action'
      end
      item "Merge".html_safe, 'javascript:void(0)',
              class: 'merge-record job-action',
              'data-confirm' => 'Are you sure? You can\'t revert this action',
              'data-url' => url_for([:merge, :admin, record]),
              'data-id' => record.id
    end
  end

end
