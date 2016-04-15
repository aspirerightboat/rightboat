class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :load_visited
  after_action :set_visited

  before_action :global_current_user
  before_action :clear_old_session

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

  def load_visited
    @visited_attrs = { action: :visited, ip: request.remote_ip }
    @visited_activity = Activity.where(@visited_attrs).first
  end

  def set_visited
    Activity.create(@visited_attrs) if @visited_activity.nil?
  end

  def require_broker_user
    if !current_broker.try(:company?)
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

  def clear_old_session
    cookies.delete(:_rightboat_session, domain: '.rightboat.com') if cookies[:_rightboat_session]
  end

  def redirect_to_not_found
    redirect_to '/404.html'
  end

  def redirect_to_maintenance
    redirect_to '/503.html'
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
