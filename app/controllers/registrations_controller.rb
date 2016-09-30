class RegistrationsController < Devise::RegistrationsController
  skip_before_action :require_confirmed_email, only: [:resend_confirmation, :confirm_email]

  def update_resource(resource, params)
    resource.update_without_password(params)
  end

  def create
    @user = User.new(params.permit(:title, :first_name, :last_name, :email, :username, :password, :password_confirmation))
    update_user_settings
    @user.role = 'PRIVATE'
    @user.assign_phone_from_leads
    @user.registered_from_affiliate = User.find_by(id: cookies[:iframe_broker_id]) if cookies[:iframe_broker_id]

    if @user.save
      env['warden'].set_user(@user)
      render json: {google_conversion: render_to_string(partial: 'shared/google_signup_conversion', locals: {form_name: 'signup_form'})}
    else
      render json: @user.errors.full_messages, root: false, status: 422
    end
  end

  def update
    user_params = params.require(:user)
                      .permit(:title, :first_name, :last_name, :email, :phone, :password, :password_confirmation, :avatar, :avatar_cache,
                              address_attributes: [:id, :line1, :line2, :county, :town_city, :zip, :country_id],
                              information_attributes: [:id, :about_me, :gender, :sail_power, :boater_type, :boating_place, :dob,
                                                       :have_boat, :boat_type, :require_finance, :require_berth])

    update_params = user_params
    user = current_user

    if update_params[:password].blank?
      update_params.delete('password')
      update_params.delete('password_confirmation')

      user.update(update_params)
    else
      if user.valid_password?(params[:user][:current_password])
        if user.update(update_params)
          sign_in user.reload
        end
      else
        user.errors.add(:current_password, 'is invalid')
      end
    end

    if user.errors.any?
      render json: user.errors.full_messages, root: false, status: 422
    else
      render json: {alert: 'Settings was saved successfully'}
    end
  end

  def confirm_email
    user = User.find(params[:user])
    if !user.email_confirmed? && user.confirm_email_token == params[:token]
      user.email_confirmed = true
      user.save!
      flash.notice = 'Your email has been confirmed'
    end

    path = user.company? ? root_path : user_area_path(user)
    redirect_to path
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
  helper_method :user_area_path
end
