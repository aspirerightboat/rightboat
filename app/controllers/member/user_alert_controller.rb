class Member::UserAlertController < Member::BaseController
  def show
    @user_alert = current_user.user_alert
  end

  def update
    current_user.user_alert.update_attributes!(user_alert_params)
    redirect_to({action: :show}, notice: 'Your settings was saved')
  end

  private

  def user_alert_params
    params.require(:user_alert).permit(:favorites, :saved_searches, :suggestions, :newsletter)
  end
end