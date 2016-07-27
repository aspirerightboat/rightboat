class RegisterBrokerController < ApplicationController
  def create
    user = User.new(params.permit(:title, :first_name, :last_name, :email, :phone, :company_name))
    user.role = User::ROLES['COMPANY']
    user.address = Address.new
    user.password = user.password_confirmation = SecureRandom.hex(5)

    if user.save
      UserMailer.broker_registered(user.id).deliver_later
      StaffMailer.broker_registered_notify_admin(user.id).deliver_later
      session[:registered_user_id] = user.id

      render json: {add_card_step: render_to_string(partial: 'add_card_step')}
    else
      render json: user.errors.full_messages, root: false, status: 422
    end
  end

  def add_card
    user = User.find(session[:registered_user_id])

    customer = Stripe::Customer.create(
        source: params[:stripe_token],
        email: user.email,
        description: user.name,
        metadata: {user_id: user.id}
    )

    stripe_card = user.stripe_card || user.build_stripe_card
    stripe_card.assign_attributes(params.permit(:user_id, :brand, :country_iso, :exp_month,
                                                :exp_year, :last4, :dynamic_last4))
    stripe_card.stripe_customer_id = customer.id
    stripe_card.save!

    StaffMailer.broker_added_card(user.id).deliver_later

    session.delete(:registered_user_id)

    render json: {thank_you_step: render_to_string(partial: 'thank_you_step', locals: {broker_name: user.name})}
  rescue Stripe::CardError => e
    render json: {error: e.message}, status: :unprocessable_entity
  end
end
