class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?

  before_action :global_current_user
  before_action :clear_old_session
  before_action :set_country_specific_units_for_non_user
  before_action :update_user_specific_settings

  serialization_scope :view_context

  Dir["#{Rails.root}/app/controllers/application_controller_ext/*"].each { |file| Rails.env.development? ? load(file) : require(file) }

  private

  def authenticate_admin_user!
    authenticate_user!
    unless current_user.admin?
      flash[:error] = 'You need admin privilege to continue. Please login as admin and try again.'
      redirect_to root_path
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:username, :email, :password, :remember_me) }
  end

  # prevent flash message in devise controller
  def is_flashing_format?
    false
  end

  def require_broker_user
    if !current_broker.try(:company?)
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

      currency = current_user&.user_setting&.currency || country.currency.name
      length_unit = current_user&.user_setting&.length_unit || country.length_unit

      set_current_currency(currency)
      set_current_length_unit(length_unit)
    end
  end

  def update_user_specific_settings
    return if !current_user || session[:user_settings].present?
    user_setting = UserSetting.find_or_create_by(user_id: current_user.id)
    set_country_specific_units

    if !cookies[:boat_type]
      user_setting.boat_type = UserActivity.favourite_boat_types_for(current_user)
      cookies[:boat_type] = user_setting.boat_type
    end

    if session[:update_user_settings]
      user_setting.country_iso = session[:country]
      user_setting.length_unit = cookies[:length_unit]
      user_setting.currency = cookies[:currency]
      session.delete :update_user_settings
    end

    set_current_currency(user_setting.currency) if user_setting.currency
    set_current_length_unit(user_setting.length_unit) if user_setting.length_unit

    session[:user_settings] = true

    user_setting.save
  end

  def require_confirmed_email
    if user_signed_in? && !current_user.email_confirmed
      redirect_to confirm_email_home_path
    end
  end

  def clear_old_session
    cookies.delete(:_rightboat_session, domain: '.rightboat.com') if cookies[:_rightboat_session]
  end

  def makemodel_boat_path(boat)
    sale_boat_path(boat.manufacturer, boat.model, boat)
  end
  helper_method :makemodel_boat_path

  def makemodel_boat_pdf_path(boat)
    sale_boat_pdf_path(boat.manufacturer, boat.model, boat)
  end
  helper_method :makemodel_boat_pdf_path
end
