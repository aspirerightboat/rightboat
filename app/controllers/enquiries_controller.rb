class EnquiriesController < ApplicationController
  before_action :authenticate_user!

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

  private

  def enquiry_params
    params.require(:enquiry).permit(:title, :first_name, :surname, :email, :phone, :message)
  end
end
