ActiveAdmin.register Currency do
  include SpellFixable
  include Sortable

  menu priority: 4

  permit_params :name, :symbol

  filter :name

  index as: :sortable_table do
    column :id
    column :name
    column :symbol
    column :rate
    column '# Boats' do |r|
      r.boats.count
    end

    actions
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :symbol
    end

    f.actions
  end

end
