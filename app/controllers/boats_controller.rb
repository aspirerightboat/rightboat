class BoatsController < ApplicationController
  before_filter :set_back_link
  after_filter :store_recent

  def show
    @boat = Boat.find(params[:id])

    respond_to do |format|
      format.html
      format.pdf { render pdf: 'show', layout: 'application' }
    end
  end

  private
  def set_back_link
    if request.referer =~ /^([^\?]+)?\/search(\?.*)?$/
      @back_url = request.referer.to_s
    end
  end

  def store_recent
    attrs = { target_id: @boat.id, action: :show, ip: request.remote_ip }

    if activity = Activity.where(attrs).first
      activity.inc(count: 1)
    else
      Activity.create(attrs.merge(user_id: current_user.try(:id)))
    end
  end
end