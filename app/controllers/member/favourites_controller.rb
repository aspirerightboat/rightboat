module Member
  class FavouritesController < BaseController
    def index
      @favourites = current_user.favourites
    end

    def create
      boat = Boat.find(params[:boat_id])
      attrs = { boat_id: boat.id, user_id: current_user.id }

      if boat.booked_by?(current_user)
        Favourite.where(attrs).delete_all
        active = false
      else
        favourite = Favourite.create!(attrs)
        active = true
      end

      render json: { active: active, ts: active ? favourite.display_ts : nil }
    end
  end
end
