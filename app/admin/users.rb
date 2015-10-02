ActiveAdmin.register User do
  permit_params :username, :email, :password, :password_confirmation,
                :first_name, :last_name, :company_name, :role,
                :avatar, :avatar_cache, :company_weburl, :company_description

  config.sort_order = 'role_asc'
  menu priority: 8

  controller do
    def update
      if params[:user][:password].blank?
        params[:user].delete("password")
        params[:user].delete("password_confirmation")
      end
      super
    end

  end

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
  filter :username
  filter :email
  filter :first_name
  filter :last_name
  filter :company_name
  filter :current_sign_in_at
  filter :sign_in_count
  filter :created_at

  form do |f|
    f.inputs "User Details" do
      f.input :role, as: :select, collection: User::ROLES, include_blank: false
      f.input :avatar, as: :file, hint: image_tag(f.object.avatar_url(:thumb))
      f.input :avatar_cache, as: :hidden
      f.input :username
      f.input :title, as: :select, collection: User::TITLES
      f.input :first_name
      f.input :last_name
      f.input :email
      f.input :password
      f.input :company_name
      f.input :company_weburl
      f.input :company_description, as: :text
      f.input :phone
      f.input :mobile
      f.input :fax

      f.has_many :address, allow_destroy: true do |addr_f|
        addr_f.input :line1
        addr_f.input :line2
        addr_f.input :town_city
        addr_f.input :county
        addr_f.input :country
        addr_f.input :zip
      end
    end
    f.actions
  end

end
