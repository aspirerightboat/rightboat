module Member
  class DashboardController < BaseController
    skip_before_action :require_user_login!, only: [:index]

    def index
      current_user.build_address if current_user && current_user.address.nil?
      current_user.build_information if current_user && current_user.information.nil?
    end

    def enquiries
      @enquiries = current_user.enquiries.includes(boat: [:currency, :primary_image, :manufacturer, :model, :country, :vat_rate])
    end
  end
end