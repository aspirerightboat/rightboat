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
    path = user.company? ? getting_started_broker_area_path : member_root_path
    if !user.email_confirmed? && user.confirm_email_token == params[:token]
      user.email_confirmed = true
      user.save!
      flash.notice = 'Your email was confirmed'
    end

    redirect_to path
  end

  def resend_confirmation
    current_user.email = params[:email]
    current_user.save!

    path = current_user.company? ? getting_started_broker_area_path : member_root_path
    current_user.send(:send_email_confirmation)

    redirect_to path, notice: 'Confirmation email was sent'
  end
end