class HomeController < ApplicationController
  before_filter :load_search_facets, only: :index
  # TODO: after_filter :register_statistics, only: :index

  def index
    if user_signed_in? && params[:popup_login]
      # root page is used as login page too routing: /sign-in
      flash[:notice] = "You have signed in already."
      return redirect_to(root_path)
    end

    @featured_boats = Boat.featured
    @recent_boats = Boat.recently_reduced
    @recent_tweets = Rightboat::TwitterFeed.all
  end

  private
  def register_statistics
    featured_boats = Rails.cache.fetch "rightboat.featured_boats", expires_in: 1.day do
      @featured_boats
    end

    unless featured_boats.blank?
      featured_boats.each do |boat|
        Statistics.record_featured_boat_view(boat)
      end
    end
  end

end