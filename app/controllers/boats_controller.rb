class BoatsController < ApplicationController
  before_filter :set_back_link, only: [:show]

  def index
    redirect_to manufacturers_path
  end

  def show
    @boat = Boat.not_deleted.find_by(slug: params[:id])
    redirect_to(manufacturers_path, alert: I18n.t('messages.boat_not_exist')) and return if !@boat
    store_recent
  end

  def pdf
    @boat = Boat.includes([user: :broker_info], :office).find_by(slug: params[:boat_id])

    lead_requested = current_user.try(:admin?) ||
        Enquiry.where(boat_id: @boat.id).where('remote_ip = ? OR user_id = ?', request.remote_ip, current_user.try(:id) || 0).exists?

    if !lead_requested
      redirect_to(boat_path(@boat.slug, anchor: 'enquiry_popup'), alert: I18n.t('messages.not_authorized')) and return
    end

    UserMailer.boat_detail(current_user.id, @boat.id).deliver_now

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
      activity.update(count: activity.count + 1)
    else
      Activity.create(attrs.merge(user_id: current_user.try(:id)))
    end
  end
end