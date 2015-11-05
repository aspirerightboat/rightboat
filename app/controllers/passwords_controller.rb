class PasswordsController < Devise::PasswordsController

  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      render json: {}
    else
      render json: ["Unfortunately, we could not find your email. Please register for a Rightboat account <a here='#' class='user-login'>here</a>.".html_safe], root: false, status: 422
    end
  end
end