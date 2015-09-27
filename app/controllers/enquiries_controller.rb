class EnquiriesController < ApplicationController

  def create
    enquiry = Enquiry.new(enquiry_params)

    captcha = Rightboat::Captcha.decrypt(params[:enquiry][:captcha_key])

    unless captcha.correct?(params[:enquiry][:captcha])
      enquiry.errors.add :captcha, "is invalid"
      render json: enquiry, serializer: ErrorSerializer, status: :unprocessable_entity, root: false
    else
      enquiry.user = current_user
      enquiry.boat = Boat.find(params[:boat_id])
      if enquiry.save
        render json: enquiry, serializer: EnquirySerializer
      else
        render json: enquiry, serializer: ErrorSerializer, status: :unprocessable_entity, root: false
      end
    end
  end

  private
  def enquiry_params
    params.require(:enquiry).permit(:title, :first_name, :surname, :email, :country_code, :phone, :message, :have_account, :password)
  end

end