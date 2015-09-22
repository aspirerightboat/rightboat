ActiveAdmin.register Enquiry, as: 'Lead' do
  permit_params :user_id, :boat_id, :title, :first_name, :surname, :email, :phone,
                :message, :remote_ip, :browser, :token, :deleted_at, :created_at, :updated_at, :status


  menu label: 'Leads', priority: 9

  config.sort_order = 'created_at_desc'

  filter :user, collection: -> { User.organizations }
  filter :created_at, label: 'Date of Lead'
  filter :status, as: :select, collection: -> { Enquiry::STATUSES }

  controller do
    def scoped_collection
      end_of_association_chain.includes(:user, boat: [:manufacturer, :model])
    end
  end

  index download_links: [:csv] do
    column 'Date of Lead', sortable: :created_at do |record|
      "#{record.created_at} (#{distance_of_time_in_words(record.created_at, Time.current)} ago)"
    end
    column :user, sortable: :user_id
    column :boat, sortable: :boat_id do |record|
      record.boat.try(&:manufacturer_model)
    end
    column 'Length(m)', sortable: 'boats.length_m' do |record|
      l = record.boat.try(&:length_m)
      l.blank? ? nil : "#{l}m"
    end
    # column 'Length(ft in)', sortable: 'boats.length_ft' do |record|
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
    # end
    column :contact_detail do |record|
      {
        'Title' => record.title,
        'Name' => record.name,
        'Country code' => record.country_code,
        'Phone' => record.phone,
        'Email' => record.email
      }.map {|k, v|
        "<b>#{k}</b>: #{v}" unless v.blank?
      }.reject(&:blank?).join('<br/>').html_safe
    end
    column :status
    actions
  end

  form do |f|
    f.inputs do
      f.input :user, as: :select, collection: User.where(id: f.object.user_id).map { |u| ["#{u.first_name}, #{u.last_name}", u.id] }
      f.input :boat, as: :select, collection: Boat.where(id: f.object.boat_id).map { |b| ["#{b.manufacturer.name}, #{b.name}", b.id] }
      f.input :status, as: :select, collection: Enquiry::STATUSES.map { |s| [s.titleize, s] }
      f.input :title, as: :select, collection: User::TITLES.map { |t| [t, t] }
      f.input :first_name
      f.input :surname
      f.input :email
      f.input :phone
      f.input :remote_ip
      f.input :browser
      f.input :token
      f.input :created_at
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
    column(:token)
    column(:remote_ip)
    column(:browser)
  end

  sidebar 'Tools', only: [:index] do
    link_to('Run approve-old-leads job', {action: :approve_old_leads}, method: :post, class: 'button')
  end

  collection_action :approve_old_leads, method: :post do
    res = LeadsApproveJob.new.perform
    redirect_to({action: :index}, notice: "#{res} leads was approved")
  end
end
