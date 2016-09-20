module Member
  class RecentViewsController < BaseController
    def index
      @viewed_boats = Boat.recently_viewed(current_customer)
                          .includes(:manufacturer, :model, :vat_rate, :country, :currency, :primary_image, user: [:comment_request])
                          .page(params[:page]).per(15)
    end
  end
end
