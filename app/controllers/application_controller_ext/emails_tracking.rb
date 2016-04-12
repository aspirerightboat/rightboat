class ApplicationController < ActionController::Base
  before_action :catch_email_click

  def catch_email_click
    if all_params_present?(params) && params[:utm_medium] == 'email'
      MailClick.create(mail_click_params_mapped(params))
      if [:token].present?
        cookies[:tracking_token]={ value: params[:token], expires: 1.day.from_now }
      end
    end
  end

  private

  def all_params_present?(params)
    %w(utm_source utm_medium utm_campaign utm_content).all? { |key| params.has_key?(key) }
  end

  def mail_click_params_mapped(params = {})
    {
        user_id: Base64.urlsafe_decode64(params[:i]),
        url: request.path,
        action_fullname: params[:utm_content],
        saved_searches_alert_id: SavedSearchesAlert.find_by(token: params[:token])&.id,
        email_sent_at: params[:sent_at]
    }
  end
end
