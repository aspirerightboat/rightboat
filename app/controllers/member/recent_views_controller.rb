module Member
  class RecentViewsController < BaseController
    def index
      @viewed_boats = Boat.recently_viewed(current_user).page(params[:page]).per(15)
    end
  end
end
