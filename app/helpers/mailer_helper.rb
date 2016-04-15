module MailerHelper
  def email_image_tag(image, options)
    if Rails.env.development?
      file_name = image.gsub('/', '_')
      attachments.inline[file_name] = File.read("#{Rails.root}/app/assets/images/#{image}")
      image_tag attachments[file_name].url, options
    else
      image_tag image, options
    end
  end

  def track_email_click_params(utm_params:, user_id:, saved_searches_alert: nil)
    if utm_params.present?
      {
          token: saved_searches_alert&.token,
          i: Base64.urlsafe_encode64(user_id.to_s, padding: false),
          utm_source: utm_params[:source] || 'subscription',
          utm_medium: utm_params[:medium] || 'email',
          utm_campaign: utm_params[:campaign],
          utm_content: utm_params[:content],
          sent_at: utm_params[:sent_at]
      }
    else
      {}
    end
  end
end
