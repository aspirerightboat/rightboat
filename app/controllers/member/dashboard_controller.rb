module Member
  class DashboardController < BaseController
    def enquiries
      @enquiries = current_user.enquiries
    end

    def subscriptions
      @subscriptions = current_user.subscriptions
    end
  end
end