ActiveAdmin.register Specification do
  include SpellFixable
  include Sortable

  menu parent: "Boats", label: "Specifications"

  permit_params :name, :display_name, :active

  filter :name
  filter :visible, as: :boolean, label: 'Public'
  filter :active, as: :boolean


  index as: :sortable_table do
    column "Name", :display_name
    column "Visible", :visible do |r|
      r.visible? ? status_tag('Public', :ok) : status_tag('Private', :error)
    end
    column "# Boats" do |r|
      r.boats.count
    end
    column "# Misspellings" do |r|
      link_to "#{r.misspellings.count} (Manage)", [:admin, r, :misspellings]
    end
    column :updated_at

    actions do |record|
      item "Toggle Visible", [:toggle_visible, :admin, record], method: :post, class: 'job-action'
      if record.active?
        item "Disable", [:disable, :admin, record], method: :post, class: 'job-action job-action-warning',
             'data-confirm' => "This specification will not appear in boat specifiaction. Are you sure?"
      else
        item "Activate", [:active, :admin, record], method: :post, class: 'job-action',
             'data-confirm' => "This specification will appear in boat specifiaction. Are you sure?"
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
      f.input :name, input_html: !f.object.new_record? ? { disabled: :disabled,
              hint: "You can't edit name. Please use `display name` or `active` feature for hide in front site"} : {}
      f.input :display_name
      f.input :active
      f.input :visible, label: 'Public'
    end

    f.actions
  end

  member_action :toggle_visible, method: :post do
    if resource.update_attributes(visible: !resource.visible?)
      flash[:notice] = "The visible status has changed."
    else
      flash[:error] = "Sorry, #{resource} can't be updated."
    end
    redirect_to :back
  end

end
