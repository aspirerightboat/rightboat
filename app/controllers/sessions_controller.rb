class SessionsController < Devise::SessionsController
  after_action :clean_up_settings_cookies, only: :destroy
  clear_respond_to
  respond_to :json

  def create
    (head :bad_request; return) unless request.xhr?
    self.resource = warden.authenticate!(auth_options)
    set_flash_message(:notice, :signed_in) if is_flashing_format?
    sign_in(resource_name, resource)
    yield resource if block_given?
    render json: { return_to: stored_location_for(resource) }
  end

  def failure
    warden_message = warden.message || :unauthenticated
    error_msg = find_message(warden_message, scope: 'devise.failure', authentication_keys: 'email')
    render json: { success: false, errors: [error_msg] }, status: 401
  end

  def auth_options
    action_for_recall = request.xhr? ? 'failure' : 'new'
    { scope: resource_name, recall: "#{controller_path}##{action_for_recall}" }
  end

  def warden_options
    env['warden.options']
  end

  def clean_up_settings_cookies
    cookies.delete :boat_type
    cookies.delete :currency
    cookies.delete :length_unit
    cookies.delete :country
  end

  def facebook_login
    auth = request.env['omniauth.auth']
    fb_info = FacebookUserInfo.find_or_initialize_by(uid: auth.uid)
    fb_info.email = auth.info.email.presence # valid email | nil
    fb_info.first_name = auth.info.first_name # eg. Lev
    fb_info.last_name = auth.info.last_name # eg. Lukomskyi
    fb_info.name = auth.info.name # eg. Lev Lukomskyi
    fb_info.gender = auth.extra.raw_info.gender # male | female
    fb_info.image_url = auth.info.image # eg. http://graph.facebook.com/769845456403892/picture
    fb_info.locale = auth.extra.raw_info.locale # eg. uk_UA
    fb_info.profile_url = auth.extra.raw_info.link # eg. https://www.facebook.com/app_scoped_user_id/769845456403892/
    fb_info.timezone = auth.extra.raw_info.timezone # eg. 2
    fb_info.age_min = auth.extra.raw_info.age_range[:min] # eg. 21
    fb_info.age_max = auth.extra.raw_info.age_range[:max] # eg. 21

    user = fb_info.user || (User.find_by(email: fb_info.email) if fb_info.email.present?) || User.new
    user.facebook_user_info = fb_info
    user.first_name ||= fb_info.first_name
    user.last_name ||= fb_info.last_name
    user.name ||= fb_info.name
    user.email = fb_info.email if user.email.blank?
    user.role ||= 'PRIVATE'
    user.password = SecureRandom.hex(10) if user.encrypted_password.blank?
    user.email_confirmed = true if fb_info.email.present?
    user.assign_phone_from_leads
    user.registered_from_affiliate = User.find_by(id: cookies[:iframe_broker_id]) if cookies[:iframe_broker_id]

    if user.save && fb_info.save
      sign_in(:user, user)
      redirect_to request.env['omniauth.origin'] || root_path
    else
      redirect_to root_path, alert: user.errors.full_messages.join('; ')
    end
  end

  def facebook_failure
    redirect_to params[:origin] || root_path
  end

end
