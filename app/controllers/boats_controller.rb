class BoatsController < ApplicationController
  before_filter :set_back_link, only: [:show]

  def index
    redirect_to manufacturers_path
  end

  def show
    @boat = Boat.find_by(slug: params[:id])
    redirect_to(manufacturers_path, alert: I18n.t('messages.boat_not_exist')) and return if !@boat || @boat.deleted?
    store_recent
  end

  def pdf
    @boat = Boat.includes([user: :broker_info], :office).find_by(slug: params[:boat_id])

    unless (current_user && current_user.admin?) || Enquiry.where(remote_ip: request.remote_ip, boat_id: @boat.id).any?
      redirect_to(boat_path(@boat.slug, anchor: 'enquiry_popup'), alert: I18n.t('messages.not_authorized')) and return
    end

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