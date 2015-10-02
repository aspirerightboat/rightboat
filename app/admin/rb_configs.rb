ActiveAdmin.register RBConfig do
  menu label: 'Settings', priority: 20

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
