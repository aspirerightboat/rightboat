class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  include ErrorsHandling
  include EmailsTracking
  include CurrentMethods

  before_action :global_current_user
  before_action :set_country_specific_units_for_non_user
  before_action :set_user_specific_settings
  before_action :remember_broker_from_iframe

  private

  def authenticate_admin_user!
    unless current_admin
      redirect_to root_path, alert: 'You need admin privilege to continue. Please login as admin and try again.'
    end
  end

  # prevent flash message in devise controller
  def is_flashing_format?
    false
  end

  def require_broker_user
    if !current_user&.company?
      redirect_to root_path, alert: 'broker user required'
    end
  end

  def global_current_user
    $current_user = current_user # or store it like this: Thread.current[:current_user] = current_user
  end

  def set_country_specific_units_for_non_user
    set_country_specific_units unless current_user
  end

  def set_country_specific_units
    if session[:country].blank?
      country_code = nil
      begin
        Timeout::timeout(1) do
          country_code = Rightboat::DbIpApi.country(request.remote_ip)
        end
      rescue Timeout::Error
        country_code = nil
      end

      country_code ||= 'GB'
      session[:country] = country_code
      country = Country.find_by(iso: country_code)

      currency = current_user&.user_setting&.currency || (country&.currency || Currency.default).name
      length_unit = current_user&.user_setting&.length_unit || country&.length_unit || 'm'

      set_current_currency(currency)
      set_current_length_unit(length_unit)
    end
  end

  def set_user_specific_settings
    return if !current_user || session[:user_settings_were_set].present?
    user_setting = UserSetting.find_or_create_by(user_id: current_user.id)
    set_country_specific_units

    if !session[:boat_type]
      user_setting.boat_type = UserActivity.favourite_boat_types_for(current_user)
      session[:boat_type] = user_setting.boat_type
    end

    if user_setting.country_iso
      session[:country] = user_setting.country_iso
    else
      user_setting.country_iso = session[:country]
    end

    if user_setting.currency
      set_current_currency(user_setting.currency)
    else
      user_setting.currency = session[:currency]
    end

    if user_setting.length_unit
      set_current_length_unit(user_setting.length_unit)
    else
      user_setting.length_unit = session[:length_unit]
    end

    session[:user_settings_were_set] = true

    user_setting.save
  end

  def require_confirmed_email
    if user_signed_in? && !current_user.email_confirmed
      redirect_to confirm_email_home_path
    end
  end

  def makemodel_boat_path(boat)
    sale_boat_path(boat.manufacturer, boat.model, boat)
  end
  helper_method :makemodel_boat_path

  def makemodel_boat_pdf_path(boat)
    sale_boat_pdf_path(boat.manufacturer, boat.model, boat)
  end
  helper_method :makemodel_boat_pdf_path

  def remember_broker_from_iframe
    if params[:iframe] && (iframe = BrokerIframe.find_by(token: params[:iframe]))
      cookies[:iframe_broker_id] = {value: iframe.user_id, expires: 4.hours.from_now}

      query_hash = Rack::Utils.parse_query(URI.parse(request.url).query).except('iframe')
      url = query_hash.empty? ? request.path : "#{request.path}?#{query_hash.to_query}"

      IframeClick.create(broker_iframe: iframe, ip: request.remote_ip, url: url, referer_url: request.referer)

      redirect_to url
    end
  end
end
