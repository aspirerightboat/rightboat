class MailSubscriptionsController < ApplicationController

  before_filter :load_subscription

  def create
    if params[:commit] == 'Subscribe'
      if @subscription
        @subscription.update(active: true) if !@subscription.active
      else
        @subscription = MailSubscription.new(mail_subscription_params)
        @subscription.active = true
        @subscription.save
      end

      @notice = 'Thank you, we have added your email address to our mailing list.'
    elsif params[:commit] == 'Unsubscribe'
      if @subscription
        @subscription.update(active: false)
      end

      @notice = 'Your email address has been removed.  You will no longer receive marketing emails from us.'
    end

    render json: { notice: @notice }, status: 200
  end

  private

  def load_subscription
    @subscription = MailSubscription.where("email like ?", mail_subscription_params[:email]).first
  end

  def mail_subscription_params
    params.fetch(:mail_subscription, {}).permit(:email)
  end
end