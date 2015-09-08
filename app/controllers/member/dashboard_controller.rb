module Member
  class DashboardController < BaseController
    def enquiries
      @enquiries = current_user.enquiries
    end

    def subscriptions
      @subscriptions = current_user.subscriptions
    end

    def information
      current_user.build_information if current_user.information.blank?
    end
  end
end