class Member::UserAlertController < Member::BaseController
  def update
    current_customer.user_alert.update_attributes!(user_alert_params)

    redirect_to member_user_notifications_path, notice: 'Your settings were saved'
  end

  private

  def user_alert_params
    params.require(:user_alert).permit(:favorites, :enquiry, :saved_searches, :suggestions, :newsletter)
  end
end
