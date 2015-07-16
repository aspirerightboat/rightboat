ActiveAdmin.register Specification do
  include SpellFixable

  config.sort_order = 'name_asc'
  menu parent: "Boats", label: "Specifications"

  permit_params :display_name, :active

  filter :name
  filter :active, as: :boolean


  index do
    column "Name", :display_name
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

  form do |f|
    f.inputs do
      f.input :name, input_html: { disabled: :disabled },
              hint: "You can't edit name. Please use `display name` or `active` feature for hide in front site"
      f.input :display_name
      # TODO: implement misspellings
    end

    f.actions
  end

end
