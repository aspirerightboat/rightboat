module Member
  class LeadsController < BaseController
    def index
      @leads = current_user.leads.order('id DESC')
                   .includes(boat: [:boat_type, :currency, :primary_image, :manufacturer, :model, :country, :vat_rate, user: [:broker_info, :comment_request]])
                   .page(params[:page]).per(15)
    end

    def unhide
      current_user.leads.update_all(hidden: false)
      render json: {}
    end

    def destroy
      lead = Lead.find(params[:id])
      lead.update(hidden: true)
      render json: {}
    end
  end
end
