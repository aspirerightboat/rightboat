ActiveAdmin.register_page 'Mails' do

  menu label: 'Mails'
  content title: "Mails" do
    columns do
      column do
        total_sent = SavedSearchesAlert.count
        total_opened = SavedSearchesAlert.where('opened_at IS NOT NULL').count
        total_clicked = MailClick.count
        total_leads = Enquiry.where('saved_searches_alert_id IS NOT NULL').count

        render partial: 'stats', locals: {
            total_sent: total_sent,
            total_opened: total_opened,
            total_clicked: total_clicked,
            total_leads: total_leads
        }
      end
    end
  end
end
