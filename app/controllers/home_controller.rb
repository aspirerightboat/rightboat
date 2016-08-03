class HomeController < ApplicationController
  # TODO: after_filter :register_statistics, only: :index

  before_action :require_confirmed_email, only: [:index]
  before_action :load_visited, only: [:index]
  after_action :set_visited, only: [:index]

  def index
    if user_signed_in? && params[:popup_login]
      # root page is used as login page too routing: /sign-in
      flash[:notice] = 'You have signed in already.'
      return redirect_to(root_path)
    end

    @newest_boats = Boat.active.order('id DESC').limit(21).includes(:currency, :manufacturer, :model, :country)
    @recent_tweets = Rails.env.development? ? [] : Rightboat::TwitterFeed.all
    load_recent_boats
    load_featured
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

  def welcome_broker
    redirect_to welcome_broker_us_path if session[:country] == 'US'
  end

  def welcome_broker_us
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
    if current_user
      fill_recent_views_for_new_user
      @recent_boats = Boat.recently_viewed(current_user).limit(3)
    elsif cookies[:recently_viewed_boat_ids]
      boat_ids = cookies[:recently_viewed_boat_ids].split(',')
      @recent_boats = Boat.active.where(id: boat_ids).includes(:currency, :manufacturer, :model, :country, :primary_image)
    end
  end

  def load_visited
    if !cookies[:visited]
      visited_attrs = {action: :visited, ip: request.remote_ip}
      @site_visited = Activity.where(visited_attrs).exists?

      if @site_visited
        cookies[:visited] = 1
      else
        Activity.create(visited_attrs)
      end
    end
  end

  def set_visited
    cookies[:visited] = 1 if @site_visited
  end

  def fill_recent_views_for_new_user
    if current_user.user_activities.empty?
      boat_ids = cookies[:recently_viewed_boat_ids]&.split(',') || []
      boat_ids.each do |boat_id|
        UserActivity.create_boat_visit(boat_id: boat_id, user: current_user)
      end
    end
  end

  def load_featured
    country = Country.find_by(iso: session[:country])

    @featured_boats = Rails.cache.fetch("featured_boats_#{session[:country]}", expires_in: 1.hours) do
      Boat.featured.active.where(country: country).order('RAND()').limit(12)
        .includes(:user, :currency, :manufacturer, :model, :country, :primary_image, :vat_rate).to_a
    end

    length = @featured_boats.length

    if length < 6
      limit = 6 - length

      if session[:country] == 'US'
        @featured_boats += Boat.featured.active
          .where.not(country: country).limit(limit).order('RAND()')
          .includes(:user, :currency, :manufacturer, :model, :country, :primary_image, :vat_rate).to_a
      else
        @featured_boats += Boat.featured.active
          .where(country_id: european_country_ids.delete_if { |x| x == country.id }).limit(limit).order('RAND()')
          .includes(:user, :currency, :manufacturer, :model, :country, :primary_image, :vat_rate).to_a
      end
    end
  end

  def european_country_ids
    Rails.cache.fetch('european_country_ids', expires_in: 24.hours) do
      Country.where(iso: %w(GB DE IT FR ES TR NL BE GR PT SE AT CH DK FI NO IE HR LU IS MC PL RU RO CZ HU)).pluck(:id)
    end
  end
end
