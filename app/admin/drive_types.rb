ActiveAdmin.register DriveType do
  include SpellFixable

  config.sort_order = 'name_asc'
  menu parent: 'Boats', priority: 4

  permit_params :name

  filter :name

  index do
    column :name
    column '# Boats' do |r|
      r.boats.count
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

end
