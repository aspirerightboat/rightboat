ActiveAdmin.register Manufacturer do
  include SpellFixable

  config.sort_order = 'name_asc'
  menu parent: "Boats", label: "Manufacturers", priority: 1

  permit_params :name, :active, :weburl, :logo, :logo_cache, :description

  filter :name
  filter :active, as: :boolean

  index do
    column :name
    column :active do |r|
      r.active? ? status_tag('Active', :ok) : status_tag('Inactive', :error)
    end
    column "# Models" do |r|
      link_to r.models.count, [:admin, r, :models]
    end
    column "# Boats" do |r|
      r.boats.count
    end
    column "# Misspellings" do |r|
      link_to "#{r.misspellings.count} (Manage)", [:admin, r, :misspellings]
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

  form html: { enctype: "multipart/form-data" } do |f|
    f.inputs do
      f.input :name
      f.input :weburl
      f.input :logo, as: :file, hint: image_tag(f.object.logo_url(:thumb))
      f.input :logo_cache, as: :hidden
      f.input :description
    end
    f.actions
  end

end
