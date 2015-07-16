ActiveAdmin.register User do
  permit_params :username, :email, :password, :password_confirmation, :first_name, :last_name, :company_name, :role

  config.sort_order = 'role_asc'
  menu priority: 8

  index do
    selectable_column
    id_column
    column :email
    column :name
    column :username
    column :role do |user|
      user.role_name
    end
    column :current_sign_in_at
    column :sign_in_count
    column :created_at
    actions
  end

  filter :role, collection: -> { User::ROLES }, as: :select
  filter :email
  filter :current_sign_in_at
  filter :sign_in_count
  filter :created_at

  form do |f|
    f.inputs "User Details" do
      f.input :username
      f.input :title, as: :select, collection: User::TITLES
      f.input :first_name
      f.input :last_name
      f.input :company_name
      f.input :role, as: :select, collection: User::ROLES, include_blank: false
      f.input :email
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end

end
