ActiveAdmin.register Model do
  include SpellFixable

  config.sort_order = 'name_asc'
  menu parent: "Boats", label: "Models", priority: 2

  permit_params :manufacturer_id, :name, :active, :sailing
  filter :name
  filter :manufacturer, collection: -> { Manufacturer.active.order("name asc") }
  filter :active, as: :boolean


  index do
    column :manufacturer, sortable: :manufacturer_id
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
    column "Sailing?", :sailing do |r|
      r.sailing? ? "Yes" : "No"
    end
    column :updated_at

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

  form do |f|
    f.inputs do
      f.input :manufacturer, as: :select, collection: Manufacturer.order(:name), include_blank: false
      f.input :name
      f.input :sailing, label:  "Is this a sailing boat?", as: :radio
    end

    f.actions
  end

end
