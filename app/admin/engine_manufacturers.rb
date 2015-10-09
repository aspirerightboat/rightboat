ActiveAdmin.register EngineManufacturer do
  include SpellFixable

  config.sort_order = 'name_asc'
  menu parent: 'Boats', label: 'Engine Manufacturers'

  permit_params :name

  filter :name
  filter :active, as: :boolean

  index do
    column :name
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
