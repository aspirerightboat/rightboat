module Member
  class RecentViewsController < BaseController
    def index
      boats_ids = current_user.user_activities.recent_views.pluck(:boat_id)
      include_models = [:manufacturer, :model, :user, :vat_rate, :country, :currency, :primary_image]
      @viewed_boats = Boat.where(id: boats_ids).includes(*include_models).page(params[:page]).per(15)
    end
  end
end
