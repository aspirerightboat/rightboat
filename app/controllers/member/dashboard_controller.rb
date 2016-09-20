module Member
  class DashboardController < BaseController
    skip_before_filter :authenticate_user!, only: [:index]

    def index
      session[:customer_id] = params[:customer_id] if current_user&.admin? && params[:customer_id].present?
    end

    def about_me
      current_customer.build_address if current_customer && current_customer.address.nil?
      current_customer.build_information if current_customer && current_customer.information.nil?
    end

    def discounts
    end
  end
end
