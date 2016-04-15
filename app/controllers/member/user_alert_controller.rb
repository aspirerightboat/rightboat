class Member::UserAlertController < Member::BaseController
  def update
    current_user.user_alert.update_attributes!(user_alert_params)
    if params[:saved_searches].present?
      saved_searches_alert_true = params[:saved_searches].select { |_, val| val == {'alert' => 'true'} }
      saved_searches_alert_false = params[:saved_searches].select { |_, val| val == {'alert' => 'false'} }

      current_user.saved_searches.where(id: saved_searches_alert_true.keys).update_all(alert: true)
      current_user.saved_searches.where(id: saved_searches_alert_false.keys).update_all(alert: false)
    end

    redirect_to( member_user_notifications_path, notice: 'Your settings were saved')
  end

  private

  def user_alert_params
    params.require(:user_alert).permit(:favorites, :enquiry, :saved_searches, :suggestions, :newsletter)
  end
end
