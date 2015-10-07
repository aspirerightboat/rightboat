class MailSubscriptionsController < ApplicationController

  def create
    if params[:commit] == 'Subscribe'
      subs = MailSubscription.find_or_initialize_by(mail_subscription_params)
      subs.deleted_at = nil
      subs.save!
      notice = 'Thank you, we have added your email address to our mailing list.'
    elsif params[:commit] == 'Unsubscribe'
      subscription = MailSubscription.find_by(mail_subscription_params)
      subscription.try(:destroy)
      notice = 'Your email address has been removed. You will no longer receive marketing emails from us.'
    end

    render json: {notice: notice}
  end

  private

  def mail_subscription_params
    params.fetch(:mail_subscription, {}).permit(:email)
  end
end