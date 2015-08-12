class BoatsController < ApplicationController
  before_filter :set_back_link

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
end