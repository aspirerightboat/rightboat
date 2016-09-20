ActiveAdmin.register User do
  permit_params :username, :email, :password, :password_confirmation,
                :first_name, :last_name, :company_name, :role, :title, :phone, :mobile, :fax,
                :avatar, :avatar_cache,
                address_attributes: [:id, :line1, :line2, :town_city, :county, :country_id, :zip, :_destroy],
                broker_info_attributes: [:id, :contact_name, :position, :description, :discount,
                                         :payment_method, :xero_contact_id,
                                         :website, :additional_email_raw, :vat_number, :logo, :lead_email_distribution, :_destroy],
                deal_attributes: [:id, :deal_type, :charges_text, :currency_id, :lead_length_rate,
                                  :lead_min_price, :lead_max_price, :flat_lead_price, :flat_month_price,
                                  :trial_started_at, :trial_ended_at, :_destroy]


  config.sort_order = 'first_name_asc_and_last_name_asc_and_created_at_desc'
  menu priority: 20

  filter :first_name_or_last_name_or_email_or_username_or_company_name_cont, as: :string, label: 'Name | Email | Username'
  filter :role, as: :select, collection: -> { User::ROLES }
  filter :username
  filter :email
  filter :first_name
  filter :last_name
  filter :company_name
  filter :address_country_id, as: :select, collection: Country.order(:name)
  filter :current_sign_in_at
  filter :sign_in_count
  filter :created_at
  filter :broker_info_payment_method, collection: -> { BrokerInfo::PAYMENT_METHODS }, as: :select, label: 'Brokers payment method'

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

    def scoped_collection
      end_of_association_chain.includes(:registered_from_affiliate, :imports, :deal, :broker_info)
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
    column :current_sign_in_at
    column :sign_in_count
    column :saved_searches_count
    column(:active_boats) do |user|
      if user.boats_count > 0
        user.boats_count
      else
        content_tag(:span, user.boats_count.to_s, class: 'status_tag red')
      end
    end
    column('Import') do |user|
      if user.company?
        import = user.imports.first
        if import
          para(style: 'text-align: center') { link_to("##{import.id}", admin_import_path(import)) }
          import.active? ? status_tag('Active', :green) : status_tag('Inactive', :red)
        else
          status_tag('No Import', :red) if user.boats_count <= 0 # if boats_count > 0 then user most likely has an expert boats
        end
      end
    end
    column('Free Trial', sortable: 'users.company_name') do |user|
      if user.company?
        if user.deal&.trial_started_at && user.deal&.trial_ended_at
          from = user.deal.trial_started_at.to_date.to_s(:db)
          to = user.deal.trial_ended_at.to_date.to_s(:db)
          days_left = case
                      when Time.current < user.deal.trial_started_at then 'Not Started'
                      when Time.current > user.deal.trial_ended_at then 'Ended'
                      else t('x_days_left', count: ((user.deal.trial_ended_at - Time.current) / 1.day).to_i)
                      end
          abbr(title: "#{from} — #{to}") { days_left }
        end
      end
    end
    column('Payment Method') do |user|
      if user.company?
        case user.broker_info&.payment_method
        when 'none' then status_tag('None', :red)
        when 'dd' then status_tag('Direct Debit', :green)
        when 'card' then status_tag('Credit Card', :green)
        end
      end
    end
    column('created_at') { |user| time_ago_with_hint(user.created_at) }
    column 'Referral' do |user|
      link_to user.registered_from_affiliate.name, admin_user_path(user.registered_from_affiliate) if user.registered_from_affiliate
    end
    actions do |user|
      item 'My Rightboat', member_root_path(customer_id: user.id), target: '_blank', class: 'member_link'
      if user.company?
        item 'Broker area', getting_started_broker_area_path(broker_id: user.id), target: '_blank', class: 'member_link'
      end
    end
  end

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
        ff.input :discount
        ff.input :website
        ff.input :additional_email_raw, label: 'Additional email(seperated by comma)', input_html: {class: 'select-array'}
        ff.input :vat_number
        ff.input :logo, as: :file, hint: image_tag(ff.object.logo_url(:thumb))
        ff.input :lead_email_distribution, as: :select, collection: ff.object.distribution_options
        ff.input :xero_contact_id
        ff.input :payment_method, as: :select, collection: BrokerInfo::PAYMENT_METHODS, include_blank: false
      end

      f.has_many :deal, allow_destroy: false, new_record: f.object.deal.blank? do |ff|
        ff.input :deal_type, as: :select, collection: Deal::DEAL_TYPES, include_blank: false, input_html: {'data-select-fields-toggler' => 'deal-type'}
        ff.input :charges_text, hint: "You can change default text for each of deal types in #{link_to 'settings', admin_rb_configs_path('q[key_contains]' => 'charges_text_')} or override it here".html_safe
        ff.input :lead_length_rate, input_html: {class: 'deal-type-standard'}
        ff.input :lead_min_price, input_html: {class: 'deal-type-standard'}
        ff.input :lead_max_price, input_html: {class: 'deal-type-standard'}
        ff.input :flat_lead_price, input_html: {class: 'deal-type-flat_lead'}
        ff.input :flat_month_price, input_html: {class: 'deal-type-flat_month'}
        ff.input :currency, as: :select, collection: Currency.all, include_blank: false
        ff.input :trial_started_at, as: :string, input_html: {class: 'datepicker', style: 'width: 100px', value: f.object.deal&.trial_started_at&.strftime('%F')}
        ff.input :trial_ended_at, as: :string, input_html: {class: 'datepicker', style: 'width: 100px', value: f.object.deal&.trial_ended_at&.strftime('%F')}
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
    column :saved_searches_count
    column(:active_boats) { |user| user.boats_count }
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
      if resource.company? || resource.facebook_user_info
        column do
          if resource.company?
            panel 'Broker Details' do
              attributes_table_for resource.broker_info do
                (BrokerInfo.column_names - %w(id user_id)).each { |column| row column }
              end
            end
            panel 'Deal' do
              attributes_table_for resource.deal do
                (Deal.column_names - %w(id user_id)).each do |column|
                  if column == 'charges_text'
                    row('Charges Text') { |deal| deal.processed_charges_text }
                  else
                    row column
                  end
                end
              end
            end
          end
          if (fb_info = resource.facebook_user_info)
            panel 'Facebook User Information' do
              para { link_to image_tag(fb_info.image_url), fb_info.profile_url }
              attributes_table_for resource.facebook_user_info do
                (FacebookUserInfo.column_names - %w(id user_id image_url profile_url)).each { |column| row column }
              end
            end
          end
        end
      end
    end
    activities = user.user_activities.recent(20)
                     .includes([
                                 {boat: [:manufacturer, :model]},
                                 {lead: :boat}
                               ])
                     .group_by { |c| c.created_at.to_date }

    render partial: 'stats', locals: {user_activities: activities}

    para {link_to 'Load history', activity_history_admin_user_path(user), class: 'button'}
  end

  member_action :activity_history, method: :get do
    user = User.find_by(slug: params[:id])
    @activities = user.user_activities.recent
        .includes([
                      {boat: [:manufacturer, :model]},
                      {lead: :boat}
                  ])
        .group_by { |c| c.created_at.to_date }
  end

  sidebar 'User Boats', only: [:show, :edit] do
    boats_count = user.boats.active.count
    inactive_count = user.boats.inactive.count
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
