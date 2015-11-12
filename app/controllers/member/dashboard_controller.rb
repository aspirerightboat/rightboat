module Member
  class DashboardController < BaseController
    skip_before_action :require_user_login!, only: [:index]

    def index
    end

    def about_me
      current_user.build_address if current_user && current_user.address.nil?
      current_user.build_information if current_user && current_user.information.nil?
    end
  end
end