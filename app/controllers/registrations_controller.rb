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
    success = if current_user.email_changed?
                current_user.save # email confirmation will be sent by reconfirm_email_if_changed before_save callback
              else
                current_user.send_email_confirmation
                true
              end
    success ? flash.notice = 'Confirmation email was sent' : flash.alert = current_user.errors.full_messages.join(', ')

    redirect_to user_area_path(current_user)
  end

  private

  def user_area_path(user)
    user.company? ? getting_started_broker_area_path : member_root_path
  end
end