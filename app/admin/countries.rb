ActiveAdmin.register Country do
  include SpellFixable

  config.sort_order = 'name_asc'
  menu priority: 10

  permit_params :name, :iso, :currency_id, :country_code, :suspicious

  filter :name
  filter :iso, label: 'ISO 3166'
  filter :suspicious

  index do
    column :id
    column :name
    column 'ISO', :iso
    column :currency
    column :country_code
    column '# Boats' do |r|
      r.boats.not_deleted.count
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
      f.input :iso, label: 'ISO'
      f.input :currency, colleciton: Currency.all
      f.input :country_code
      f.input :suspicious
    end

    f.actions
  end

end
