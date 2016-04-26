class ApplicationController < ActionController::Base
  before_action :load_visited
  after_action :set_visited

  private

  def load_visited
    if !cookies[:visited]
      visited_attrs = {action: :visited, ip: request.remote_ip}
      @site_visited = Activity.where(visited_attrs).exists?
      Activity.create(visited_attrs) unless @site_visited
    end
  end

  def set_visited
    cookies[:visited] = 1 if @site_visited
  end

end
