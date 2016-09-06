ActiveAdmin.register Lead, as: 'Lead' do
  permit_params :user_id, :boat_id, :title, :first_name, :surname, :email, :phone, :bad_quality_reason, :bad_quality_comment,
                :message, :remote_ip, :browse, :deleted_at, :created_at, :updated_at, :status, :email_sent

  menu label: 'Leads', priority: 25

  config.sort_order = 'created_at_desc_and_first_name_asc_and_surname_asc'
  actions :all, except: [:destroy]

  filter :name_cont, as: :string, label: 'Customer'
  filter :boat_user_id, as: :select, collection: User.companies, label: 'Broker'
  filter :boat_import_import_type, as: :select, collection: Rightboat::Imports::ImporterBase.import_types, label: 'Import type'
  filter :id
  filter :created_at, label: 'Date of Lead'
  filter :updated_at, label: 'Last Status Change'
  filter :month, as: :select, collection: (1..12)
  filter :status, as: :select, collection: -> { Lead::STATUSES }
  filter :saved_searches_alert_id, label: 'Mail ID'
  filter :created_from_affiliate_id, as: :select, collection: User.where(id: BrokerIframe.pluck('DISTINCT user_id')), label: 'Affiliate'

  scope :from_affiliates

  controller do
    def scoped_collection
      end_of_association_chain.includes(:user, :created_from_affiliate, boat: [:manufacturer, :model, :user, :currency])
    end
  end

  index download_links: [:csv] do
    column :id
    column('Date of Lead', sortable: :created_at) { |lead| lead.created_at.strftime('%d %b %H:%M') }
    column :customer, sortable: :name do |lead|
      div { lead.user ? link_to(lead.name, admin_user_path(lead.user)) : lead.name }
      div { lead.email } if !lead.user
      div { lead_phone(lead) } if lead.phone.present?
      div { ip_link(lead.remote_ip) }
    end
    column('Member?', sortable: :user_id) { |lead| yes_no_status(lead.user.present?) }
    column(:broker) { |lead| link_to lead.broker, admin_user_path(lead.boat.user) }
    column(:boat, sortable: :boat_id) { |lead| boat_link(lead.boat) }
    column('Boat length', sortable: 'boats.length_m') { |lead| boat_length_with_hint(lead.boat) }
    column('Boat price') { |lead| boat_admin_price(lead.boat) }
    column :status do |lead|
      div { lead.status }
      if lead.status == 'suspicious'
        div { link_to 'Release', release_admin_lead_path(lead), method: :post }
      end
    end
    column('Last Status Change', sortable: :updated_at) { |lead| time_ago_with_hint(lead.updated_at) }
    column('Lead Price') do |lead|
      price = number_to_currency(lead.lead_price, unit: lead.lead_price_currency.symbol, precision: 2)
      if lead.lead_price_currency.name == 'GBP'
        b { price }
      else
        abbr(title: "£#{lead.lead_price_gbp&.round(2)&.try_skip_fraction}") { price }
      end
    end
    column('Mail ID', sortable: :saved_searches_alert_id) do |lead|
      if lead.saved_searches_alert_id.present?
        link_to(lead.saved_searches_alert_id, admin_saved_searches_alert_path(lead.saved_searches_alert_id))
      end
    end
    column 'Referral' do |lead|
      link_to lead.created_from_affiliate.name, admin_user_path(lead.created_from_affiliate) if lead.created_from_affiliate
    end
    actions do |lead|
      item 'Delete', delete_admin_lead_path(lead), class: 'delete-lead'
    end
  end

  form do |f|
    f.inputs do
      f.input :user, as: :select, collection: User.where(id: f.object.user_id).map { |u| ["#{u.first_name}, #{u.last_name}", u.id] }
      f.input :boat, as: :select, collection: Boat.where(id: f.object.boat_id).map { |b| ["#{b.manufacturer.name}, #{b.name}", b.id] }
      f.input :status, as: :select, collection: Lead::STATUSES.map { |s| [s.titleize, s] }, include_blank: false
      f.input :title, as: :select, collection: User::TITLES.map { |t| [t, t] }
      f.input :first_name
      f.input :surname
      f.input :email
      f.input :phone
      f.input :remote_ip
      f.input :browser
      f.input :bad_quality_reason, as: :select, collection: Lead::BAD_QUALITY_REASONS.map { |r| [r.titleize, r] }, prompt: 'Please select...'
      f.input :bad_quality_comment
    end
    actions
  end

  csv do
    column(:id)
    column('Date of Lead') { |lead| lead.created_at }
    column('User') { |lead| lead.user&.name }
    column('Member?') { |lead| lead.user ? 'Yes' : 'No' }
    column('Broker') { |lead| lead.boat&.user&.name }
    column('Boat') { |lead| lead.boat&.manufacturer_model }
    column('Length') { |lead|
      if lead.boat&.length_m
        "#{lead.boat.length_m.round(2)}m"
      elsif lead.boat&.length_f
        "#{lead.boat.length_f.round(2)}ft"
      end
    }
    column(:title)
    column(:first_name)
    column(:last_name) { |lead| lead.surname }
    column(:country_code)
    column(:phone)
    column(:email)
    column(:message)
    column(:status)
    column('Last Status Change') { |lead| lead.updated_at }
    column(:lead_price) { |lead| number_to_currency(lead.lead_price, unit: lead.lead_price_currency.symbol, precision: 2) }
    column('Lead Price £') { |lead| lead.lead_price_gbp&.try_skip_fraction }
    column(:remote_ip)
    column(:browser)
  end

  sidebar 'Tools', only: [:index] do
    link_to('Run approve-old-leads job', {action: :approve_old_leads}, method: :post, class: 'button')
  end

  sidebar 'Leads Total Price', only: [:index] do
    b {
      price = Lead.ransack(params[:q]).result.sum('lead_price / lead_price_currency_rate').round
      number_to_currency(price, unit: Currency.default.symbol, precision: 0)
    }
  end

  collection_action :approve_old_leads, method: :post do
    res = Rightboat::LeadsApprover.approve_recent
    redirect_to({action: :index}, notice: "#{res} leads was approved")
  end

  member_action :delete, method: :post do
    @lead = Lead.find(params[:id])
    @lead.update status: 'deleted', bad_quality_comment: params[:reason]
    redirect_to :back, notice: 'Lead deleted successfully'
  end

  member_action :release, method: :post do
    @lead = Lead.find(params[:id])
    @lead.update status: 'pending'
    redirect_to :back, notice: 'Lead released successfully'
  end
end
