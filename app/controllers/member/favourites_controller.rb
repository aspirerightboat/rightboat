module Member
  class FavouritesController < BaseController
    def index
      @favourites = current_user.favourites.includes(boat: [:currency, :primary_image, :manufacturer, :model, :country, :vat_rate]).order(created_at: :desc)
    end

    def create
      boat = Boat.find(params[:boat_id])

      favorite = boat.favourites.where(user: current_user)

      if boat.favourited_by?(current_user)
        favorite.delete_all
        active = false
      else
        favorite.create!
        active = true
      end

      render json: {active: active}
    end
  end
end
