module Member
  class EnquiriesController < BaseController
    def index
      @enquiries = current_user.enquiries.includes(boat: [:user, :boat_type, :currency, :primary_image, :manufacturer, :model, :country, :vat_rate]).order('id DESC')
    end

    def unhide
      current_user.enquiries.update_all(deleted_at: nil)
      render json: {}
    end

    def destroy
      @enquiry = Enquiry.find(params[:id])
      @enquiry.destroy
      render json: {}
    end
  end
end
