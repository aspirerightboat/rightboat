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

  def confirm_email
    user = User.find(params[:user])
    if !user.email_confirmed? && user.confirm_email_token == params[:token]
      user.email_confirmed = true
      user.save!
      flash.notice = 'Your email was confirmed'
    end

    redirect_to user_area_path(user)
  end

  def resend_confirmation
    current_user.email = params[:email]
    if current_user.email_changed?
      current_user.save!
    else
      current_user.send_email_confirmation
    end

    redirect_to user_area_path(current_user), notice: 'Confirmation email was sent'
  end

  private

  def user_area_path(user)
    user.company? ? getting_started_broker_area_path : member_root_path
  end
end