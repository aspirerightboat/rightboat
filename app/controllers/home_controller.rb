class HomeController < ApplicationController
  before_filter :load_search_facets, only: :index
  # TODO: after_filter :register_statistics, only: :index

  def index
    if user_signed_in? && params[:popup_login]
      # root page is used as login page too routing: /sign-in
      flash[:notice] = "You have signed in already."
      return redirect_to(root_path)
    end

    @featured_boats = Rails.cache.fetch "rb.featured_boats", expires_in: 1.hour do
      Boat.featured.limit(6)
    end
    @recent_boats = Boat.where(id: Activity.recent.show.where(ip: request.remote_ip).limit(3).pluck(:target_id))
    @recent_tweets = Rightboat::TwitterFeed.all
  end

  def contact
    @page_title = 'Support and Contact'
  end

  def toc
    @page_title = 'Terms and Conditions'
  end

  def marine_services
    @pate_title = 'Maring Services'
  end

  def cookies_policy
    @page_title = 'Cookies Policy'
  end

  private
  def register_statistics
    unless @featured_boats.blank?
      @featured_boats.each do |boat|
        Statistics.record_featured_boat_view(boat)
      end
    end
  end

end