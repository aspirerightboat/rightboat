ActiveAdmin.register Lead, as: 'Lead' do
  permit_params :user_id, :boat_id, :title, :first_name, :surname, :email, :phone, :bad_quality_reason, :bad_quality_comment,
                :message, :remote_ip, :browse, :deleted_at, :created_at, :updated_at, :status, :email_sent

  menu label: 'Leads', priority: 25

  config.sort_order = 'created_at_desc_and_first_name_asc_and_surname_asc'
  actions :all, except: [:destroy]

  filter :name_cont, as: :string, label: 'Customer'
  filter :boat_user_id, as: :select, collection: User.companies, label: 'Broker'
  filter :id
  filter :created_at, label: 'Date of Lead'
  filter :updated_at, label: 'Last Status Change'
  filter :status, as: :select, collection: -> { Lead::STATUSES }
  filter :saved_searches_alert_id, label: 'Mail ID'

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
    column(:broker, sortable: 'boats.user_id') { |lead| user_admin_link(lead.boat.user) }
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
    column('Lead Price £') { |lead| b { lead.lead_price } }
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
    column('Date of Lead') { |record| record.created_at }
    column('User') { |record| record.user.try(&:name) }
    column('Member?') { |record| record.user ? 'Yes' : 'No' }
    column('Broker') { |record| record.boat.user.name }
    column('Boat') { |record| record.boat.try(&:manufacturer_model) }
    column('Length') { |record|
      l = record.boat.try(&:length_m)
      l if l.present?
    }
    # column('Length(ft in)') { |record|
    #   out = ""
    #   if boat = record.boat
    #     if boat.length_ft.present?
    #       out << "#{boat.length_ft}ft "
    #     end
    #     if boat.length_in.present?
    #       out << "#{boat.length_in}in"
    #     end
    #   end
    #   out
    # }
    column(:title)
    column(:first_name)
    column(:last_name) { |record| record.surname }
    column(:country_code)
    column(:phone)
    column(:email)
    column(:message)
    column(:status)
    column('Last Status Change') { |record| record.updated_at }
    column(:lead_price)
    column(:remote_ip)
    column(:browser)
  end

  sidebar 'Tools', only: [:index] do
    link_to('Run approve-old-leads job', {action: :approve_old_leads}, method: :post, class: 'button')
  end

  sidebar 'Stats', only: [:index] do
    "<b>Total leads price: #{leads.not_deleted.sum(:lead_price)}</b>".html_safe
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
