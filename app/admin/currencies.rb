ActiveAdmin.register Currency do
  include SpellFixable
  include Sortable

  menu priority: 4

  permit_params :name, :symbol, :active

  filter :active
  filter :name

  index as: :sortable_table do
    column :id
    column :name
    column :symbol
    column :rate
    column :active
    column "# Boats" do |r|
      r.boats.count
    end

    actions do |record|
      if record.active?
        item "Disable", [:disable, :admin, record], method: :post, class: 'job-action job-action-warning',
             'data-confirm' => "The boats belonged to #{record} will not appear. Are you sure?"
      else
        item "Activate", [:active, :admin, record], method: :post, class: 'job-action',
             'data-confirm' => "The boats belonged to #{record} will appear. Are you sure?"
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :symbol
    end

    f.actions
  end

end
