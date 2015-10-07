ActiveAdmin.register EngineModel do
  include SpellFixable

  config.sort_order = 'name_asc'
  menu parent: 'Boats', label: 'Engine Models'

  permit_params :name, :engine_manufacturer_id

  filter :name
  filter :engine_manufacturer

  index do
    column :name
    column :engine_manufacturer, sortable: false
    column '# Boats' do |r|
      r.boats.count
    end
    column '# Misspellings' do |r|
      link_to "#{r.misspellings.count} (Manage)", [:admin, r, :misspellings]
    end
    column :updated_at
    actions do |record|
      item 'Merge', 'javascript:void(0)',
              class: 'merge-record job-action',
              'data-url' => url_for([:merge, :admin, record]),
              'data-id' => record.id
    end
  end

end
