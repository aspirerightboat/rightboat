class BerthEnquiriesController < ApplicationController

  def create
    @berth_enquiry = current_user.berth_enquiries.new(berth_enquiry_params)

    if @berth_enquiry.save
      render json: {}, status: 200
    else
      render json: { errors: @berth_enquiry.errors }, status: 422
    end
  end

  private

  def berth_enquiry_params
    params.fetch(:berth_enquiry, {})
      .permit(:buy, :rent, :home, :short_term, :length_min, :length_max, :length_unit, :location, :latitude, :longitude)
  end
end