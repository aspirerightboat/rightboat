class ApplicationController < ActionController::Base
  before_action :catch_email_click

  def catch_email_click
    if all_params_present?(params) && params[:utm_medium] == 'email'
      #TODO create mail click
    end
  end

  private

  def all_params_present?(params)
    %w(utm_source utm_medium utm_campaign utm_content).all? { |key| params.has_key?(key) }
  end
end
