class RegisterBrokerController < ApplicationController
  def create
    user = User.new(params.permit(:title, :first_name, :last_name, :email, :phone, :company_name))
    user.role = User::ROLES['COMPANY']
    user.address = Address.new
    pass = SecureRandom.hex(5)
    user.password = user.password_confirmation = pass

    if user.save
      env['warden'].set_user(user)
      UserMailer.broker_registered(user.id, pass).deliver_later
      UserMailer.broker_registered_notify_admin(user.id).deliver_later

      render json: {location: broker_area_url}
    else
      render json: user.errors.full_messages, root: false, status: 422
    end
  end
end
