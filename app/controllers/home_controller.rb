class HomeController < ApplicationController
  before_action :require_confirmed_email, only: [:index]
  before_action :load_visited, only: [:index]
  after_action :set_visited, only: [:index]

  def index
    if params[:popup_login] && user_signed_in?
      redirect_to(root_path) and return
    end

    load_recent_boats
  end

  def contact
    @page_title = 'Support and Contact'
  end

  def toc
    @page_title = 'Terms and Conditions'
  end

  def privacy_policy
    @page_title = 'Privacy Policy'
  end

  def cookies_policy
    @page_title = 'Cookies Policy'
  end

  def confirm_email
  end

  def sell_my_boats
  end

  def welcome
    render layout: false
  end

  def welcome_broker
    redirect_to welcome_broker_us_path if session[:country] == 'US'
  end

  def welcome_broker_us
  end

  def welcome_popup
    session[:welcome_popup_shown] = 1
    render json: {show_popup: render_to_string(partial: 'home/welcome_popup', formats: [:html])}
  end

  private

  def load_recent_boats
    if current_user
      boat_ids = current_user.user_activities.where(kind: 'boat_view')
                     .order('id DESC').group(:boat_id).limit(3).pluck(:boat_id)
      if boat_ids.empty? && cookies[:recently_viewed_boat_ids]
        boat_ids = Boat.where(id: cookies.delete(:recently_viewed_boat_ids).split(',')).limit(3).pluck(:id)
        boat_ids.each { |boat_id| UserActivity.create_boat_visit(boat_id: boat_id, user: current_user) }
      end
      if boat_ids.any?
        @recent_boats = Boat.active.where(id: boat_ids)
                            .includes(:manufacturer, :model, :country, :currency, :primary_image).to_a
      end
    elsif cookies[:recently_viewed_boat_ids]
      boat_ids = cookies[:recently_viewed_boat_ids].split(',')
      @recent_boats = Boat.active.where(id: boat_ids)
                          .includes(:currency, :manufacturer, :model, :country, :primary_image).to_a
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

end
