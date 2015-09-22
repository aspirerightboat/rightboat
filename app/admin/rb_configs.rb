ActiveAdmin.register RBConfig do
  menu priority: 10

  permit_params :key, :value, :description

  index do
    column :key
    column :value
    column :description
    actions
  end

  # form do |f|
  #   f.inputs do
  #     f.input :alias_string, label: "Name"
  #   end
  #   f.actions
  # end

end
