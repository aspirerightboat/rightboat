class RegisterBrokerController < ApplicationController
  def create
    user = User.new(params.permit(:title, :first_name, :last_name, :email, :phone, :company_name))
    user.role = User::ROLES['COMPANY']
    user.address = Address.new
    user.password = user.password_confirmation = SecureRandom.hex(5)

    if user.save
      # env['warden'].set_user(user)
      UserMailer.broker_registered(user.id).deliver_later
      StaffMailer.broker_registered_notify_admin(user.id).deliver_later

      render json: {}
    else
      render json: user.errors.full_messages, root: false, status: 422
    end
  end
end
