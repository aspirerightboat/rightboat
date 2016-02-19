ActiveAdmin.register RBConfig do
  menu label: 'Settings', priority: 50

  permit_params :key, :value, :kind, :description

  index do
    column :key
    column :value
    column :kind
    column :description
    actions
  end

end
