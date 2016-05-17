ActiveAdmin.register_page 'Mails' do

  menu label: 'Mails'

  content title: "Mails" do

    columns do
      column do
        @created_at_gteq = (Time.current - 1.week).to_date.to_s(:db)
        @created_at_lteq = (Time.current).to_date.to_s(:db)

        if params[:q]
          @created_at_lteq = params[:q][:created_at_lteq]
          @created_at_gteq = params[:q][:created_at_gteq]
        end

        render partial: 'filters', locals: {created_at_gteq: @created_at_gteq, created_at_lteq: @created_at_lteq}

        total_sent = SavedSearchesAlert.where(created_at: @created_at_gteq.to_date.beginning_of_day.. @created_at_lteq.to_date.end_of_day).count
        total_opened = SavedSearchesAlert.where('opened_at IS NOT NULL').where(opened_at: @created_at_gteq.to_date.beginning_of_day.. @created_at_lteq.to_date.end_of_day).count
        total_clicked = MailClick.where(created_at: @created_at_gteq.to_date.beginning_of_day.. @created_at_lteq.to_date.end_of_day).count
        total_leads = Lead.where('saved_searches_alert_id IS NOT NULL').where(created_at: @created_at_gteq.to_date.beginning_of_day.. @created_at_lteq.to_date.end_of_day).count

        render partial: 'stats', locals: {
            total_sent: total_sent,
            total_opened: total_opened,
            total_clicked: total_clicked,
            total_leads: total_leads,
            created_at_gteq: @created_at_gteq,
            created_at_lteq: @created_at_lteq
        }
      end
    end
  end
end
