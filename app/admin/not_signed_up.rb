ActiveAdmin.register Enquiry, as: 'Not Signed Up' do
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
    column :last_name, sortable: :surname do |enquiry|
      enquiry.surname
    end
    column :email
    column :date_of_first_lead, sortable: :created_at do |enquiry|
      enquiry.created_at
    end
    column :telephone_number, sortable: :phone do |enquiry|
      "#{enquiry.country_code} #{enquiry.phone}"
    end
    column :emailed, sortable: :email_sent do |enquiry|
     if enquiry.email_sent
       'Yes'
       else
         form_for enquiry, url: admin_lead_path(enquiry), method: :put do |f|
           f.hidden_field :email_sent, value: true
           f.submit 'Sent'
         end
       end
     end
  end
end