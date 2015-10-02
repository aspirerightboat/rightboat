module Member
  class DashboardController < BaseController
    skip_before_action :require_user_login!, only: [:index]

    def index
    end

    def enquiries
      @enquiries = current_user.enquiries
    end

    def information
      current_user.build_information if current_user.information.blank?
    end
  end
end