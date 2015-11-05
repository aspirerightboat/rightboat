class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  after_action :set_visited

  before_action :global_current_user

  include SessionSetting

  serialization_scope :view_context

  def current_currency
    @current_currency ||= Currency.cached_by_name(cookies[:currency]) || set_currency
  end

  def set_currency(currency_name = nil)
    @current_currency = Currency.cached_by_name(currency_name) if currency_name
    @current_currency ||= (Country.find_by(iso: request.location.country_code).try(:currency) if request.location)
    @current_currency ||= Currency.default
    cookies[:currency] = @current_currency
    @current_currency
  end

  def current_length_unit
    @_current_length_unit ||= cookies[:length_unit] || 'ft'
  end

  def current_view_layout
    @_current_view_layout ||= cookies[:view_layout] || 'gallery'
  end

  def current_order_field
    @_current_order_field ||= cookies[:order_field] || 'score'
  end
  helper_method :current_currency, :current_view_layout,
                :current_order_field, :current_length_unit

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

  def load_search_facets
    search = Sunspot.search(Boat) do |q|
      q.with :live, true
      q.facet :country_id
      q.stats :year
      q.stats :price
      q.stats :length_m
    end

    price_data = search.stats(:price).data
    year_data = search.stats(:year).data
    length_data = search.stats(:length_m).data

    country_facet = search.facet(:country_id).rows
    countries_for_select = Country.where(id: country_facet.map(&:value)).order(:name).pluck(:id, :name).map do |id, name|
      ["#{name} (#{country_facet.find { |x| x.value == id }.count})", id]
    end

    @search_facets = {
      min_price:  (price_data && price_data['min'].floor) || 0,
      max_price:  (price_data && price_data['max'].ceil) || 10000,
      min_year:   (year_data && year_data['min'].floor) || 1970,
      min_length: (length_data && length_data['min'].floor) || 10,
      max_length: (length_data && length_data['max'].ceil) || 1000,
      countries_for_select: countries_for_select
    }
  end

  # prevent flash message in devise controller
  def is_flashing_format?
    false
  end

  def set_visited
    cookies[:visited] = true if cookies[:visited].nil?
  end

  def require_broker_user
    if !current_user.try(:company?) && !current_user.try(:admin?)
      redirect_to root_path, alert: 'broker user required'
    end
  end

  def global_current_user
    $current_user = current_user # or store it like this: Thread.current[:current_user] = current_user
  end

  def require_confirmed_email
    if user_signed_in? && !current_user.email_confirmed
      redirect_to confirm_email_home_path
    end
  end
end
