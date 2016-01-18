ActiveAdmin.register Enquiry, as: 'Lead' do
  permit_params :user_id, :boat_id, :title, :first_name, :surname, :email, :phone,
                :message, :remote_ip, :browse, :deleted_at, :created_at, :updated_at, :status, :email_sent


  menu label: 'Leads', priority: 9

  config.sort_order = 'created_at_desc_and_first_name_asc_and_surname_asc'

  filter :boat_user_id, as: :select, collection: User.organizations, label: 'Broker'
  filter :created_at, label: 'Date of Lead'
  filter :status, as: :select, collection: -> { Enquiry::STATUSES }

  controller do
    def scoped_collection
      end_of_association_chain.includes(:user, boat: [:manufacturer, :model, :user, :currency])
    end
  end

  index download_links: [:csv] do
    column :id
    column 'Date of Lead', sortable: :created_at do |record|
      ago = distance_of_time_in_words(record.created_at, Time.current)
      date = l record.created_at, format: :short
      "<abbr title='#{date}'>#{ago} ago</abbr>".html_safe
    end
    column :customer, sortable: :first_name do |lead|
      res = ''.html_safe
      res << link_to(lead.user.name, admin_user_path(lead.user)) if lead.user
      res << '<br>'.html_safe
      res << {
          'Title' => lead.title,
          'Name' => lead.name,
          'Country code' => lead.country_code,
          'Phone' => lead.phone,
          'Email' => lead.email
      }.map { |k, v|
        "<b>#{html_escape k}</b>: #{html_escape v}" if v.present?
      }.compact.join('<br>').html_safe
      res
    end
    column 'Member?' do |lead|
      lead.user ? status_tag('Yes', :yes) : status_tag('No', :no)
    end
    column :broker, sortable: 'boats.user_id' do |lead|
      link_to lead.boat.user.name, admin_user_path(lead.boat.user)
    end
    column :boat, sortable: :boat_id do |lead|
      link_to lead.boat.manufacturer_model, lead.boat
    end
    column 'Boat length', sortable: 'boats.length_m' do |lead|
      length_m = lead.boat.length_m
      if length_m
        length_ft = lead.boat.length_ft
        "<abbr title='#{length_ft}ft'>#{length_m}m</abbr>".html_safe
      end
    end
    column 'Boat price' do |lead|
      "#{lead.boat.price} #{lead.boat.safe_currency.symbol}" if !lead.boat.poa? && lead.boat.price > 0
    end
    column :status
    column :lead_price do |lead|
      "<b>#{lead.lead_price}</b> £".html_safe
    end
    actions
  end

  form do |f|
    f.inputs do
      f.input :user, as: :select, collection: User.where(id: f.object.user_id).map { |u| ["#{u.first_name}, #{u.last_name}", u.id] }
      f.input :boat, as: :select, collection: Boat.where(id: f.object.boat_id).map { |b| ["#{b.manufacturer.name}, #{b.name}", b.id] }
      f.input :status, as: :select, collection: Enquiry::STATUSES.map { |s| [s.titleize, s] }, include_blank: false
      f.input :title, as: :select, collection: User::TITLES.map { |t| [t, t] }
      f.input :first_name
      f.input :surname
      f.input :email
      f.input :phone
      f.input :remote_ip
      f.input :browser
    end
    actions
  end

  csv do
    column(:id)
    column('Date of Lead') { |record| record.created_at }
    column('User') { |record| record.user.try(&:name) }
    column('Boat') { |record| record.boat.try(&:manufacturer_model) }
    column('Length(m)') { |record|
      l = record.boat.try(&:length_m)
      "#{l}m" if l.present?
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
    column(:name)
    column(:country_code)
    column(:phone)
    column(:email)
    column(:message)
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
    res = LeadsApproveJob.new.perform
    redirect_to({action: :index}, notice: "#{res} leads was approved")
  end
end
