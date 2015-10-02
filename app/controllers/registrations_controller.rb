class RegistrationsController < Devise::RegistrationsController
  def update_resource(resource, params)
    resource.update_without_password(params)
  end

  def create
    user = User.new(params.permit(:title, :first_name, :last_name, :email, :username, :password, :password_confirmation))
    user.role = 'PRIVATE'

    if user.save
      env['warden'].set_user(user)
      render json: {}
    else
      render json: user.errors.full_messages, root: false, status: 422
    end
  end
end