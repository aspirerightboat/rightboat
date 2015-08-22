ActiveAdmin.register Country do
  include SpellFixable

  config.sort_order = 'name_asc'
  menu priority: 4

  permit_params :name, :iso, :currency_id, :active

  filter :active
  filter :name
  filter :iso, label: 'ISO 3166'

  index do
    column :id
    column :name
    column 'ISO', :iso
    column :active
    column :currency
    column "# Boats" do |r|
      r.boats.count
    end
    column "# Misspellings" do |r|
      link_to "#{r.misspellings.count} (Manage)", [:admin, r, :misspellings]
    end

    actions do |record|
      if record.active?
        item "Disable", [:disable, :admin, record], method: :post, class: 'job-action job-action-warning',
             'data-confirm' => "The boats belonged to #{record} will not appear. Are you sure?"
      else
        item "Activate", [:active, :admin, record], method: :post, class: 'job-action',
             'data-confirm' => "The boats belonged to #{record} will appear. Are you sure?"
      end
      item "Merge".html_safe, 'javascript:void(0)',
              class: 'merge-record job-action',
              'data-url' => url_for([:merge, :admin, record]),
              'data-id' => record.id
    end
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :iso, label: 'ISO'
      f.input :currency, colleciton: Currency.active
    end

    f.actions
  end

end
