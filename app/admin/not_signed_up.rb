ActiveAdmin.register Lead, as: 'Not Signed Up' do
	menu parent: 'Users'
  actions :index

  filter :first_name_or_surname_cont, as: :string, label: 'Name'

  controller do
    def scoped_collection
      end_of_association_chain.where(user_id: nil).group(:email)
    end
  end

  index do
    column :first_name
    column :last_name, sortable: :surname do |lead|
      lead.surname
    end
    column :email
    column :date_of_first_lead, sortable: :created_at do |lead|
      lead.created_at
    end
    column :telephone_number, sortable: :phone do |lead|
      "#{lead.country_code} #{lead.phone}"
    end
    column :emailed, sortable: :email_sent do |lead|
      if lead.email_sent
        'Yes'
      else
        link_to 'Sent', admin_lead_path(lead, lead: {email_sent: true}), method: :put
      end
    end
  end
end
