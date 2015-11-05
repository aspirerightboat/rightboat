class BerthEnquiriesController < ApplicationController

  def create
    @berth_enquiry = current_user.berth_enquiries.new(berth_enquiry_params)

    if @berth_enquiry.save
      render json: {}, status: 200
    else
      render json: @berth_enquiry.errors.full_messages, root: false, status: 422
    end
  end

  private

  def berth_enquiry_params
    params.fetch(:berth_enquiry, {})
      .permit(:buy, :rent, :home, :short_term, :location, :latitude, :longitude)
      .merge(length_min: params[:length_min], length_max: params[:length_max], length_unit: params[:length_unit])
  end
end