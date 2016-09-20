class Member::UserNotificationsController < Member::BaseController
  def index
    @user_alert = current_customer.user_alert
    @saved_searches = current_customer.saved_searches.order('id DESC').to_a
  end
end
