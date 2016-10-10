class Member::BoatsController < Member::BaseController
  before_action :ensure_non_broker

  def index
    @my_boats = current_user.boats.not_deleted.includes(:currency, :manufacturer, :model, :country, :primary_image, :vat_rate)
  end

  def pay_initial_fee
    user = current_user

    customer = Stripe::Customer.create(
        source: params.delete(:stripe_token),
        email: user.email,
        description: user.name,
        metadata: {user_id: user.id}
    )

    stripe_card = user.stripe_card || user.build_stripe_card
    stripe_card.assign_attributes(params.permit(:user_id, :brand, :country_iso, :exp_month,
                                                :exp_year, :last4, :dynamic_last4))
    stripe_card.stripe_customer_id = customer.id
    stripe_card.save!

    fee = BrokerInfo.privatee_broker_fee(session[:country])

    Stripe::Charge.create(
        amount: (fee[:price] + (fee[:vat] || 0)) * 100, # amount in cents
        currency: fee[:currency].name.downcase,
        customer: stripe_card.stripe_customer_id,
        description: 'Broker vessel listing fee'
    )

    user.role = User::ROLES['COMPANY']
    user.company_name = user.full_name
    user.build_broker_info(paid_initial_fee: true, payment_method: 'card')
    user.save!

    StaffMailer.user_paid_initial_fee(user.id).deliver_later

    render json: {redirect_to: broker_area_my_boats_path}
  rescue Stripe::CardError => e
    render json: {error: e.message}, status: :unprocessable_entity
  end

  private

  def ensure_non_broker
    redirect_to broker_area_my_boats_path if current_user.company?
  end

end
