class HomeController < ApplicationController
  before_filter :load_search_facets, only: :index

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
end