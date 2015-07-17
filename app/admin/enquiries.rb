ActiveAdmin.register Enquiry, as: 'Lead' do
  menu label: 'Leads', priority: 9

  config.sort_order = 'created_at_desc'

  filter :user, collection: -> { User.organizations }
  filter :created_at, label: 'Date of Lead'

  controller do
    def scoped_collection
      end_of_association_chain.includes(:boat)
    end
  end

  index download_links: [:csv] do
    column 'Date of Lead', sortable: :created_at do |record|
      record.created_at
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
        'Phone' => record.phone,
        'Email' => record.email
      }.map {|k, v|
        "<b>#{k}</b>: #{v}" unless v.blank?
      }.reject(&:blank?).join('<br/>').html_safe
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
      l.blank? ? nil : "#{l}m"
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
    column(:phone)
    column(:email)
    column(:message)
    column(:chase_sent)
    column(:eyb_processed)
    column(:token)
    column(:dev_res)
    column(:remote_ip)
    column(:browser)
  end
end
