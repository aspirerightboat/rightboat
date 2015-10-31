class BoatsController < ApplicationController
  before_filter :set_back_link, only: [:show]
  after_filter :store_recent, only: [:show]

  def index
    redirect_to manufacturers_path
  end

  def show
    @boat = Boat.find(params[:id])
  end

  def pdf
    @boat = Boat.find(params[:boat_id])
    render pdf: 'pdf',
           layout: 'pdf',
           margin: { bottom: 16 },
           footer: {
               html: {
                   template:  'shared/_pdf_footer.html.haml',
                   layout:    'pdf'
               }
           }

  end

  private

  def set_back_link
    if request.referer =~ /^([^\?]+)?\/search(\?.*)?$/
      @back_url = request.referer.to_s
    end
  end

  def store_recent
    attrs = { target_id: @boat.id, action: :show, ip: request.remote_ip }

    if (activity = Activity.where(attrs).first)
      activity.inc(count: 1)
    else
      Activity.create(attrs.merge(user_id: current_user.try(:id)))
    end
  end
end