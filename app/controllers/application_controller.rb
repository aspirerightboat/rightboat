class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  after_action :set_visited

  before_action :global_current_user

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
      min_price:  (price_data && price_data['min'].try(:floor)) || 0,
      max_price:  (price_data && price_data['max'].try(:ceil)) || 10000,
      min_year:   (year_data && year_data['min'].try(:floor)) || 1970,
      min_length: (length_data && length_data['min'].try(:floor)) || 10,
      max_length: (length_data && length_data['max'].try(:ceil)) || 1000,
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
