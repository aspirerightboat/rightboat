ActiveAdmin.register Manufacturer do
  include SpellFixable

  config.sort_order = 'name_asc'
  menu parent: 'Boats', label: 'Manufacturers', priority: 1

  permit_params :name, :weburl, :logo, :logo_cache, :description, :featured, :caption

  filter :name
  filter :featured

  index do
    column :id
    column :name
    column '# Models' do |r|
      link_to r.models.count, [:admin, r, :models]
    end
    column '# Boats' do |r|
      r.boats.not_deleted.count
    end
    column '# Misspellings' do |r|
      link_to "#{r.misspellings.count} (Manage)", [:admin, r, :misspellings]
    end
    column :caption
    column :featured
    column :updated_at
    actions do |record|
      item 'Merge', 'javascript:void(0)',
              class: 'merge-record job-action',
              'data-url' => url_for([:merge, :admin, record]),
              'data-id' => record.id
    end
  end

  form html: {enctype: 'multipart/form-data'} do |f|
    f.inputs do
      f.input :name
      f.input :weburl
      f.input :logo, as: :file, hint: (image_tag(f.object.logo_url(:thumb)) if f.object.logo.present?)
      f.input :logo_cache, as: :hidden
      f.input :caption
      f.input :featured, as: :boolean
      f.input :description
    end
    f.actions
  end

  controller do
    def find_resource
      Manufacturer.find_by(slug: params[:id]) || Manufacturer.find(params[:id])
    end
  end

end
