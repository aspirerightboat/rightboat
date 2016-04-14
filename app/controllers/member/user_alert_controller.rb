class Member::UserAlertController < Member::BaseController
  def show
    @user_alert = current_user.user_alert
    redirect_to( member_user_notifications_path)
  end

  def update
    current_user.user_alert.update_attributes!(user_alert_params)
    current_user.saved_searches.update_all(alert: user_alert_params[:saved_searches])
    redirect_to( member_user_notifications_path, notice: 'Your settings were saved')
  end

  private

  def user_alert_params
    params.require(:user_alert).permit(:favorites, :enquiry, :saved_searches, :suggestions, :newsletter)
  end
end
