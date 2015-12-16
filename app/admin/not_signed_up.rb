ActiveAdmin.register_page 'Not Signed Up' do
	menu parent: 'Users'

  content do
    columns do
      column do
        panel 'Not Signed Up' do
          table_for Enquiry.where(user_id: nil) do |t|
            t.column('First Name') { |enquiry| enquiry.first_name }
            t.column('Last Name') { |enquiry| enquiry.surname }
            t.column('Email') { |enquiry| link_to enquiry.email, admin_lead_path(enquiry) }
            t.column('Emailed') do |enquiry|
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
      end
    end
  end
end