module Member
  class FavouritesController < BaseController
    def index
      @favourite_boats = Boat.active
                             .joins(:favourites).where('favourites.user_id = ?', current_customer.id).order('favourites.id DESC')
                             .includes(:currency, :primary_image, :manufacturer, :model, :country, :vat_rate, user: [:comment_request])
                             .page(params[:page]).per(15)
    end

    def create
      boat = Boat.find(params[:boat_id])

      favorite_rel = boat.favourites.where(user: current_customer)

      if boat.favourited_by?(current_customer)
        favorite_rel.delete_all
        active = false
      else
        favorite_rel.create!
        active = true
      end

      render json: {active: active}
    end
  end
end
