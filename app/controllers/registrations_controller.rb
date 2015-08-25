class RegistrationsController < Devise::RegistrationsController
  clear_respond_to
  respond_to :json

  def update_resource(resource, params)
    resource.update_without_password(params)
  end

  protected

  def sign_up_params
    devise_parameter_sanitizer.sanitize(:sign_up) { |x| x.permit(:email, :first_name, :last_name, :title, :username, :passsword, :password_confirmation) }
  end
end