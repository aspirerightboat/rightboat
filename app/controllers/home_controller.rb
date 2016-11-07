class HomeController < ApplicationController
  before_action :require_confirmed_email, only: [:index]
  before_action :load_visited, only: [:index]
  after_action :set_visited, only: [:index]

  def index
    if params[:popup_login] && user_signed_in?
      redirect_to(root_path) and return
    end
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
