class BrokerAreaController < ApplicationController
  before_action :require_broker_user

  def show
    redirect_to({action: :getting_started})
  end

  def getting_started
  end

  def details
    current_user.address ||= Address.new
    @offices = current_user.offices.includes(:address).to_a
  end

  def update_details
    if current_user.update(user_params)
      render json: {location: url_for(action: :details)}
    else
      render json: current_user.errors.full_messages, root: false, status: 422
    end
  end

  def preferences
  end

  def update_preferences
    redirect_to({action: :details}, notice: 'coming soon')
  end

  def charges
  end

  def messages
  end

  def boats_overview
  end

  def boats_manager
  end

  def my_leads
    rel = current_user.enquiries.includes(boat: [:manufacturer, :model]).order('id DESC')
    @pending_leads = Enquiry.where(status: %w(pending quality_check)).merge(rel).page(params[:page]).per(15)
    @history_leads = Enquiry.where(status: %w(approved rejected invoiced)).merge(rel).page(params[:page2]).per(15)
  end

  private

  def user_params
    params.require(:user).permit(:company_name, :phone, :company_weburl,
                                 address_attributes: [:id, :line1, :line2, :county, :town_city, :zip, :country_id],
                                 offices_attributes: [:id, :name, :contact_name, :daytime_phone, :evening_phone, :mobile,
                                                      :fax, :email, :website, :_destroy])
  end
end
