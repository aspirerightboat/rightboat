module Member
  class EnquiriesController < BaseController
    def index
      @enquiries = current_user.enquiries.includes(boat: [:boat_type, :currency, :primary_image, :manufacturer, :model, :country, :vat_rate, user: :broker_info]).order('id DESC')
    end

    def unhide
      current_user.enquiries.update_all(hidden: false)
      render json: {}
    end

    def destroy
      @enquiry = Enquiry.find(params[:id])
      @enquiry.update(hidden: true)
      render json: {}
    end
  end
end
