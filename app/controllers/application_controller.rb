class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  after_action :set_visited

  include SessionSetting

  serialization_scope :view_context

  def current_currency
    return @_current_currency if @_current_currency

    if cookies[:currency]
      @_current_currency = Currency.find_by_name(cookies[:currency])
      return @_current_currency if @_current_currency
    end

    set_currency
  end

  def current_length_unit
    @_current_length_unit ||= cookies[:length_unit] ? cookies[:length_unit] : 'ft'
  end

  def current_view_layout
    @_current_view_layout ||= cookies[:view_layout] ? cookies[:view_layout] : 'gallery'
  end

  def current_order_field
    @_current_order_field ||= cookies[:order_field] ? cookies[:order_field] : 'score'
  end
  helper_method :current_currency, :current_view_layout,
                :current_order_field, :current_length_unit

  private

  def authenticate_admin_user!
    authenticate_user!
    unless current_user.admin?
      flash[:error] = "You need admin privilege to continue. Please login as admin and try again."
      redirect_to root_path
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:title, :username, :email, :first_name, :last_name, :phone, :password, :password_confirmation, :remember_me) }
    devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:username, :email, :password, :remember_me) }
    devise_parameter_sanitizer.for(:account_update) { |u| u.permit(:title, :username, :email, :first_name, :last_name, :phone, :password, :password_confirmation, :current_password,
      information_attributes: [:id, :require_finance, :list_boat_for_sale, :buy_this_season, :looking_for_berth]) }
  end

  def load_search_facets
    search = Sunspot.search(Boat) do |q|
      q.with :live, true
      q.facet :manufacturer_model
      q.facet :category_id
      q.facet :country_id
      q.stats :year
      q.stats :price
      q.stats :length_m
    end

    price_data = search.stats(:price).data
    year_data = search.stats(:year).data
    length_data = search.stats(:length_m).data

    @search_facets = {
      min_price:  (price_data && price_data['min'].floor) || 0,
      max_price:  (price_data && price_data['max'].ceil) || 10000,
      min_year:   (year_data && year_data['min'].floor) || 1970,
      min_length: (length_data && length_data['min'].floor) || 10,
      max_length: (length_data && length_data['max'].ceil) || 1000,
      categories: BoatCategory.active.where(id: search.facet(:category_id).rows.map(&:value)),
      countries: Country.active.where(id: search.facet(:country_id).rows.map(&:value))
    }
  end

  # prevent flash message in devise controller
  def is_flashing_format?
    false
  end

  def set_visited
    cookies[:visited] = true if cookies[:visited].nil?
  end
end
