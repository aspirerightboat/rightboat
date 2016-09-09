ActiveAdmin.register BoatType do
  include SpellFixable

  config.sort_order = 'name_asc'
  menu parent: 'Boats', priority: 4

  permit_params :name

  filter :name
  filter :name_stripped, as: :select, colleciton: BoatType::GENERAL_TYPES

  index do
    column :name
    column '# Boats' do |r|
      r.boats.active.count
    end
    column '# Misspellings' do |r|
      link_to "#{r.misspellings.count} (Manage)", [:admin, r, :misspellings]
    end

    actions do |record|
      item 'Merge', 'javascript:void(0)',
              class: 'merge-record job-action',
              'data-url' => url_for([:merge, :admin, record]),
              'data-id' => record.id
    end
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :name_stripped, as: :select, collection: BoatType::GENERAL_TYPES, include_blank: false
    end

    f.actions
  end
end
