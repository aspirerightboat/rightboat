module Member
  class DashboardController < BaseController
    skip_before_action :authenticate_user!, only: [:index]

    def index
    end

    def about_me
      current_user.build_address unless current_user.address
      current_user.build_information unless current_user.information
    end

    def discounts
    end
  end
end
