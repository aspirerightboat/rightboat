class RegisterBrokerController < ApplicationController
  def show
    @user = User.new
  end

  def create
    user = User.new(params.permit(:title, :first_name, :last_name, :email, :phone,
                                  :company_name, :password, :password_confirmation))
    user.role = 'COMPANY'

    user.validate
    user.errors.add(:base, 'You must agree with terms and conditions') if params[:agree].blank?

    if user.errors.none? && user.save
      env['warden'].set_user(user)
      render json: {location: broker_area_url}
    else
      render json: user.errors.full_messages, root: false, status: 422
    end
  end
end