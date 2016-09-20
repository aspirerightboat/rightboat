class Member::UserNotificationsController < Member::BaseController
  def index
    @user_alert = current_user.user_alert
    @saved_searches = current_user.saved_searches.order('id DESC').to_a
  end
end
