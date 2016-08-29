module BrokerArea
  class ChargesController < CommonController

    def index
      @payment_method = current_broker.broker_info.payment_method
      @card = current_broker.stripe_card
      @charges_text = current_broker.deal.processed_charges_text
    end

    def update_card
      stripe_card = current_broker.stripe_card

      if stripe_card
        customer = Stripe::Customer.retrieve(stripe_card.stripe_customer_id)
        customer.source = params[:stripe_token]
        customer.save
      else
        customer = Stripe::Customer.create(
            source: params[:stripe_token],
            email: current_broker.email,
            description: current_broker.name,
            metadata: {user_id: current_broker.id}
        )
        stripe_card = current_broker.build_stripe_card(stripe_customer_id: customer.id)
      end

      stripe_card.assign_attributes(params.permit(:user_id, :brand, :country_iso, :exp_month,
                                                  :exp_year, :last4, :dynamic_last4))
      stripe_card.save!
      current_broker.broker_info.update(payment_method: 'card')

      StaffMailer.broker_updated_card(current_broker.id).deliver_later

      render json: {card_info: render_to_string(partial: 'card_info', locals: {:@card => stripe_card})}
    rescue Stripe::CardError => e
      render json: {error: e.message}, status: :unprocessable_entity
    end

  end
end
