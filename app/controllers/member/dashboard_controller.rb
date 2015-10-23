module Member
  class DashboardController < BaseController
    skip_before_action :require_user_login!, only: [:index]

    def index
    end

    def enquiries
      @enquiries = current_user.enquiries.includes(boat: [:currency, :primary_image, :manufacturer, :model, :country, :vat_rate])
    end

    def information
      current_user.build_information if current_user.information.blank?
    end
  end
end