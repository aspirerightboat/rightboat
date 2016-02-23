ActiveAdmin.register Manufacturer do
  include SpellFixable
  include MisspellFixer

  config.sort_order = 'name_asc'
  menu parent: 'Boats', label: 'Manufacturers', priority: 1

  permit_params :name, :weburl, :logo, :logo_cache, :description

  filter :name

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
    column :updated_at
    actions do |record|
      item 'Merge', 'javascript:void(0)',
              class: 'merge-record job-action',
              'data-url' => url_for([:merge, :admin, record]),
              'data-id' => record.id
    end
  end

  form html: { enctype: 'multipart/form-data'} do |f|
    f.inputs do
      f.input :name
      f.input :weburl
      f.input :logo, as: :file, hint: image_tag(f.object.logo_url(:thumb))
      f.input :logo_cache, as: :hidden
      f.input :description
    end
    f.actions
  end

  controller do
    def find_resource
      if params[:action].in?(%w(fetch_name fix_name))
        Model.where(id: params[:id]).first!
      else
        super
      end
    end
  end
end
