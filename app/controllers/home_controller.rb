class HomeController < ApplicationController
  # TODO: after_filter :register_statistics, only: :index

  before_action :require_confirmed_email, only: [:index]
  before_filter :load_recent_boats, only: [:index]

  def index
    if user_signed_in? && params[:popup_login]
      # root page is used as login page too routing: /sign-in
      flash[:notice] = 'You have signed in already.'
      return redirect_to(root_path)
    end

    @featured_boats = Rails.cache.fetch 'rb.featured_boats', expires_in: 1.hour do
      Boat.includes(:currency, :manufacturer, :model, :country, :primary_image, :vat_rate).featured.not_deleted.order('RAND()')
    end
    @newest_boats = Boat.order('id DESC').limit(21).includes(:currency, :manufacturer, :model, :country)
    @recent_tweets = Rails.env.development? ? [] : Rightboat::TwitterFeed.all
  end

  def contact
    @page_title = 'Support and Contact'
  end

  def toc
    @page_title = 'Terms and Conditions'
  end

  def marine_services
    @pate_title = 'Marine Services'
  end

  def privacy_policy
    @page_title = 'Privacy Policy'
  end

  def cookies_policy
    @page_title = 'Cookies Policy'
  end

  def confirm_email
  end

  def welcome
    render layout: false
  end

  private
  def register_statistics
    unless @featured_boats.blank?
      @featured_boats.each do |boat|
        Statistics.record_featured_boat_view(boat)
      end
    end
  end

  def load_recent_boats
    if cookies[:recently_viewed_boat_ids]
      boat_ids = cookies[:recently_viewed_boat_ids].split(',')
    else
      boat_ids = []
    end

    @recent_boats = Boat.active.where(id: boat_ids).includes(:currency, :manufacturer, :model, :country, :primary_image)
  end

end
