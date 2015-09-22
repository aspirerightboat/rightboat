class EnquiriesController < ApplicationController
  before_action :authenticate_user!
  before_action :load_enquiry, only: [:show, :approve, :quality_check]
  before_action :require_broker, only: [:approve, :quality_check]
  before_action :require_buyer_or_broker, only: [:show]

  def create
    enquiry = current_user.enquiries.new(enquiry_params)

    if !Rightboat::Captcha.correct?(session[:captcha].with_indifferent_access, params[:enquiry][:captcha])
      enquiry.captcha_correct = false
    end

    enquiry.boat = Boat.find(params[:boat_id])
    if enquiry.save
      session.delete(:captcha)
      LeadsMailer.delay.lead_created_notify_buyer(enquiry) #.deliver_now
      LeadsMailer.delay.lead_created_notify_broker(enquiry) #.deliver_now
      render json: enquiry, serializer: EnquirySerializer, root: false
    else
      session[:captcha] = Rightboat::Captcha.generate
      render json: enquiry, serializer: ErrorSerializer, status: :unprocessable_entity, root: false
    end
  end

  def show
    @boat = @enquiry.boat
  end

  def approve
    @enquiry.status = 'approved'
    @enquiry.save!
    redirect_to({action: :show}, {notice: 'Lead approved'})
  end

  def quality_check
    @enquiry.status = 'quality_check'
    @enquiry.save! # email should be sent on after_save callback
    redirect_to({action: :show}, {notice: 'Lead will be reviewed by Rightboat staff'})
  end

  private

  def enquiry_params
    params.require(:enquiry).permit(:title, :first_name, :surname, :email, :phone, :message)
  end

  def load_enquiry
    @enquiry = Enquiry.find(params[:id])
  end

  def require_broker
    if !can_view_as_broker(current_user)
      redirect_to '/403.html', status: 403
    end
  end

  def require_buyer_or_broker
    if !can_view_as_broker(current_user) && !can_view_as_buyer(current_user)
      redirect_to '/403.html', status: 403
    end
  end

  def can_view_as_broker(broker_user)
    broker_user && broker_user.company? && @enquiry.boat.user == broker_user
  end

  def can_view_as_buyer(user)
    @enquiry.user == user
  end
end
