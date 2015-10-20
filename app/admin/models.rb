ActiveAdmin.register Model do
  include SpellFixable

  config.sort_order = 'name_asc'
  menu parent: 'Boats', label: 'Models', priority: 2

  belongs_to :manufacturer, optional: true

  permit_params :manufacturer_id, :name, :sailing
  filter :name
  filter :manufacturer, collection: -> { Manufacturer.order(:name) }


  index do
    column :id
    column :manufacturer, sortable: :manufacturer_id
    column :name
    column '# Boats' do |r|
      r.boats.count
    end
    column '# Misspellings' do |r|
      link_to "#{r.misspellings.count} (Manage)", [:admin, r, :misspellings]
    end
    column 'Sailing?', sortable: :sailing do |r|
      r.sailing? ? status_tag('Yes', :ok) : status_tag('No')
    end
    column :updated_at

    actions do |record|
      item 'Merge', 'javascript:void(0)',
              class: 'merge-record job-action',
              'data-url' => url_for([:merge, :admin, record]),
              'data-id' => record.id
    end
  end

  form do |f|
    f.inputs do
      f.input :manufacturer, as: :select, collection: Manufacturer.order(:name), include_blank: false
      f.input :name
      f.input :sailing, label: 'Is this a sailing boat?', as: :radio
    end

    f.actions
  end

  controller do
    def scoped_collection
      Model.includes(:manufacturer)
    end
  end
end
