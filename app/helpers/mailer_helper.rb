module MailerHelper
  def track_email_click_params(utm_params, saved_searches_alert_token = nil)
    {
        token: saved_searches_alert_token,
        utm_source: utm_params[:source] || 'subscription',
        utm_medium: utm_params[:source] || 'email',
        utm_campaign: utm_params[:campaign],
        utm_content: utm_params[:content]
    }
  end
end
