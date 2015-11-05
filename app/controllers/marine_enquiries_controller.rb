class MarineEnquiriesController < ApplicationController

  def create
    @marine_enquiry = MarineEnquiry.new(marine_enquiry_params)

    if @marine_enquiry.save
      render json: {}, status: 200
    else
      render json: @marine_enquiry.errors.full_messages, root: false, status: 422
    end
  end

  private

  def marine_enquiry_params
    params.fetch(:marine_enquiry, {})
      .permit(:first_name, :last_name, :email, :title, :country_code, :phone, :comments, :enquiry_type)
  end
end