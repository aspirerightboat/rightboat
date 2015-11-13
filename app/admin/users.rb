ActiveAdmin.register User do
  permit_params :username, :email, :password, :password_confirmation,
                :first_name, :last_name, :company_name, :role, :title, :phone, :mobile, :fax,
                :avatar, :avatar_cache,
                address_attributes: [:id, :line1, :line2, :town_city, :county, :country_id, :zip, :_destroy],
                broker_info_attributes: [:id, :contact_name, :position, :description, :lead_rate, :discount, :website, :additional_email, :vat_number, :logo, :copy_to_head_office, :_destroy]

  config.sort_order = 'role_asc'
  menu priority: 8

  before_save do |user|
    user.updated_by_admin = true
  end

  controller do
    def update
      if params[:user][:password].blank?
        params[:user].delete('password')
        params[:user].delete('password_confirmation')
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
      f.input :phone
      f.input :mobile
      f.input :fax

      f.has_many :address, allow_destroy: true do |ff|
        ff.input :line1
        ff.input :line2
        ff.input :town_city
        ff.input :county
        ff.input :country, as: :select, collection: Country.order(:name)
        ff.input :zip
      end

      f.has_many :broker_info, allow_destroy: true do |ff|
        ff.input :contact_name
        ff.input :position
        ff.input :description
        ff.input :lead_rate
        ff.input :discount
        ff.input :website
        ff.input :additional_email
        ff.input :vat_number
        ff.input :logo
        ff.input :copy_to_head_office
      end
    end
    f.actions
  end

  sidebar 'Tools', only: [:show, :edit] do
    boats_count = user.boats.not_deleted.count
    inactive_count = user.boats.deleted.count
    s = "<p>Boats: <b>#{boats_count} active</b>, <b>#{inactive_count} inactive</b></p>"
    if boats_count > 0 || inactive_count > 0
      s << '<p>'
      s << link_to('Activate all boats', {action: :activate_boats, id: user, do: :activate}, method: :post, class: 'button', style: 'margin-bottom: 8px', data: {disable_with: 'working...'}) if inactive_count > 0
      s << link_to('Deactivate all boats', {action: :activate_boats, id: user, do: :deactivate}, method: :post, class: 'button', data: {disable_with: 'working...'}) if boats_count > 0
      s << '</p>'
    end
    s.html_safe
  end

  member_action :activate_boats, method: :post do
    activate = params[:do] == 'activate'
    resource.boats.each do |boat|
      activate ? (boat.revive if boat.deleted?) : (boat.destroy if !boat.deleted_at)
    end
    redirect_to (request.referer || {action: :index}), notice: "All boats of #{resource.name} was #{activate ? 'activated' : 'deactivated'}"
  end

end
