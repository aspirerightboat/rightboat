ActiveAdmin.register Model do
  include SpellFixable

  config.sort_order = 'name_asc'
  menu parent: "Boats", label: "Models", priority: 2

  belongs_to :manufacturer, optional: true

  permit_params :manufacturer_id, :name, :active, :sailing
  filter :name
  filter :manufacturer, collection: -> { Manufacturer.active.order("name asc") }
  filter :active, as: :boolean


  index do
    column :id
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
    column "Sailing?", sortable: :sailing do |r|
      r.sailing? ? status_tag("Yes", :ok) : status_tag("No")
    end
    column :updated_at

    actions do |record|
      if record.active?
        item "Disable", [:disable, :admin, record], method: :post, class: 'job-action job-action-warning', 'data-confirm' => 'These models will not be shown. Are you sure?'
      else
        options = record.manufacturer.active? ? {} : {'data-confirm' => "The manufacturer is not activated. These models wil not appear until manufacturer[#{model.manufactuer}] activated."}
        item "Activate", [:active, :admin, record], options.merge(method: :post, class: 'job-action')
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
