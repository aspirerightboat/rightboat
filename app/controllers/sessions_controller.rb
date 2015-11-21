class SessionsController < Devise::SessionsController
  protect_from_forgery except: :create # temporary fix for "Can't verify CSRF token authenticity" error on prod
  skip_before_action :require_confirmed_email, only: [:destroy]
  clear_respond_to
  respond_to :json

  def create
    self.resource = warden.authenticate!(auth_options)
    set_flash_message(:notice, :signed_in) if is_flashing_format?
    sign_in(resource_name, resource)
    yield resource if block_given?
    render json: { return_to: stored_location_for(resource) }
  end

  def failure
    warden_message = warden.message || :unauthenticated
    error_msg = find_message(warden_message, scope: 'devise.failure', authentication_keys: 'username/email')
    render json: { success: false, errors: [error_msg] }, status: 401
  end

  def auth_options
    action_for_recall = request.xhr? ? 'failure' : 'new'
    { scope: resource_name, recall: "#{controller_path}##{action_for_recall}" }
  end

  def warden_options
    env['warden.options']
  end
end