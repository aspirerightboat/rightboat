ActiveAdmin.register User do
  permit_params :username, :email, :password, :password_confirmation,
                :first_name, :last_name, :company_name, :role, :title, :phone, :mobile, :fax,
                :avatar, :avatar_cache,
                address_attributes: [:id, :line1, :line2, :town_city, :county, :country_id, :zip, :_destroy],
                broker_info_attributes: [:id, :contact_name, :position, :description, :discount,
                                         :lead_length_rate, :lead_min_price, :lead_max_price, :payment_method,
                                         :website, :additional_email, :vat_number, :logo, :lead_email_distribution, :_destroy]

  config.sort_order = 'first_name_asc_and_last_name_asc_and_created_at_desc'
  menu priority: 20

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
    column :name
    column :email
    column :role do |user|
      user.role_name
    end
    column :no_of_active_boats, sortable: 'boats_count' do |user|
      user.boats_count
    end
    column :current_sign_in_at
    column :sign_in_count
    column('created_at') { |user| time_ago_with_hint(user.created_at) }
    actions do |user|
      if user.company?
        link_to 'Broker area', getting_started_broker_area_path(broker_id: user.id), target: '_blank'
      end
    end
  end

  filter :first_name_or_last_name_or_email_or_username_cont, as: :string, label: 'Name | Email | Username'
  filter :role, as: :select, collection: -> { User::ROLES }
  filter :username
  filter :email
  filter :first_name
  filter :last_name
  filter :company_name
  filter :current_sign_in_at
  filter :sign_in_count
  filter :created_at
  filter :broker_info_payment_method, collection: -> { BrokerInfo::PAYMENT_METHODS }, as: :select, label: 'Brokers payment method'

  form do |f|
    f.inputs 'User Details' do
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

      f.has_many :address, allow_destroy: false, new_record: f.object.address.blank? do |ff|
        ff.input :line1
        ff.input :line2
        ff.input :town_city
        ff.input :county
        ff.input :country, as: :select, collection: Country.order(:name)
        ff.input :zip
      end

      f.has_many :broker_info, allow_destroy: false, new_record: f.object.broker_info.blank? do |ff|
        ff.input :contact_name
        ff.input :position
        ff.input :description
        ff.input :lead_length_rate
        ff.input :lead_min_price
        ff.input :lead_max_price
        ff.input :discount
        ff.input :website
        ff.input :additional_email
        ff.input :vat_number
        ff.input :logo
        ff.input :lead_email_distribution, as: :select, collection: ff.object.distribution_options
        ff.input :xero_contact_id
        ff.input :payment_method, as: :select, collection: BrokerInfo::PAYMENT_METHODS, include_blank: false
      end
    end
    f.actions
  end

  csv do
    column :id
    column :title
    column :first_name
    column :last_name
    column :email
    column :username
    column :slug
    column :company_name
    column :role
    column :no_of_active_boats do |user|
      user.boats_count
    end
    column :sign_in_count
    column :phone
    column :fax
    column :mobile
    column :security_question
    column :security_answer
    column :fax
    column :mobile
    column :description
    column :contact1
    column :contact2
    column :source
    column :company_weburl
    column :active
    column :email_confirmed
    column :payment_method do |user|
      user.broker_info.payment_method if user.company?
    end
  end

  show do
    columns do
      column do
        panel 'User Details' do
          attributes_table_for resource do
            User.columns.each { |column|
              if column.name.end_with?('_sign_in_ip')
                row(column.name) { ip_link user.send(column.name) }
              else
                row column.name
              end
            }
          end
        end
      end
      if resource.company?
        column do
          panel 'Broker Details' do
            attributes_table_for resource.broker_info do
              BrokerInfo.columns.each { |column| row column.name.to_sym unless column.name.in?(%w(id user_id)) }
            end
          end
        end
      end
    end
  end

  sidebar 'User Boats', only: [:show, :edit] do
    boats_count = user.boats.not_deleted.count
    inactive_count = user.boats.deleted.count
    s = "<p><b>#{boats_count} active</b>, <b>#{inactive_count} inactive</b></p>"
    if boats_count > 0 || inactive_count > 0
      s << '<p>'
      # s << link_to('Delete all permanently', {action: :activate_boats, id: user, do: :delete_perm}, method: :post, class: 'button', data: {disable_with: 'working...'}) if boats_count > 0
      # s << link_to('Delete all', {action: :activate_boats, id: user, do: :delete}, method: :post, class: 'button', data: {disable_with: 'working...'}) if boats_count > 0
      s << link_to('Deactivate all', {action: :activate_boats, id: user, do: :mark_deleted}, method: :post, class: 'button', data: {disable_with: 'working...'}) if boats_count > 0
      s << link_to('Activate all', {action: :activate_boats, id: user, do: :unmark_deleted}, method: :post, class: 'button', data: {disable_with: 'working...'}) if inactive_count > 0
      s << '</p><p>'
      s << link_to('View all', admin_boats_path(q: {user_id_eq: user.id}, commit: 'Filter', order: 'id_desc'))
      s << '</p>'
    end
    s.html_safe
  end

  member_action :activate_boats, method: :post do
    case params[:do]
    when 'delete_perm' then resource.boats.each { |b| b.destroy(:force) }
    when 'delete' then resource.boats.each { |b| b.destroy }
    when 'mark_deleted' then resource.boats.not_deleted.each { |b| b.destroy }
    when 'unmark_deleted' then resource.boats.deleted.each { |b| b.revive }
    end

    redirect_to (request.referer || {action: :index}), notice: "For all boats of #{resource.name} action was taken #{params[:do]}d"
  end

end
