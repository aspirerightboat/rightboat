module Member
  class RecentViewsController < BaseController
    def index
      include_models = [:manufacturer, :model, :user, :vat_rate, :country, :currency, :primary_image]
      @viewed_boats = Boat.joins(:user_activities)
        .where(user_activities: {kind: :boat_view})
        .where(user_activities: {user_id: current_user.id})
        .order('user_activities.id DESC').uniq.includes(*include_models).page(params[:page]).per(15)
    end
  end
end
