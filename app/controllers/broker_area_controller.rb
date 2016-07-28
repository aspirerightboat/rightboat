class BrokerAreaController < ApplicationController
  before_action :require_broker_user, except: [:tc, :getting_started]

  def show
    redirect_to({action: :getting_started})
  end

  def getting_started
    cookies[:broker_id] = params[:broker_id] if current_user&.admin? && params[:broker_id].present?
  end

  def details
    current_broker.build_address if !current_broker.address
    current_broker.build_broker_info if !current_broker.broker_info
    @offices = current_broker.offices.includes(address: :country).to_a
  end

  def update_details
    if current_broker.update(user_params)
      render json: {location: url_for(action: :details)}
    else
      render json: current_broker.errors.full_messages, root: false, status: 422
    end
  end

  def preferences
  end

  def change_password
    @user = current_broker
    if !@user.valid_password?(params[:old_password])
      redirect_to({action: :preferences}, alert: 'Old password is incorrect')
      return
    end

    if @user.update_attributes(params.permit(:password, :password_confirmation))
      sign_in @user, bypass: true
      redirect_to({action: :preferences}, notice: 'Your settings was saved')
    else
      redirect_to({action: :preferences}, alert: current_broker.errors.full_messages.join('. '))
    end
  end

  def update_preferences
    redirect_to({action: :details}, notice: 'coming soon')
  end

  def messages
  end

  def boats_overview
    @last_imported_at = Import.find_by(user: current_broker).try(:last_import_trail).try(:finished_at)
  end

  def boats_manager
  end

  def my_leads
    rel = current_broker.broker_leads.includes(boat: [:manufacturer, :model]).order('id DESC')
    @pending_leads = Lead.where(status: %w(pending quality_check)).merge(rel).page(params[:page]).per(15)
    @history_leads = Lead.where(status: %w(approved rejected invoiced)).merge(rel).page(params[:page2]).per(15)
  end

  def tc
  end

  def account_history
    @leads = current_broker.broker_leads.where.not(invoice_id: nil).includes(:invoice, boat: [:manufacturer, :model, :currency])
                 .order('id DESC').page(params[:page]).per(30)
  end

  private

  def user_params
    params.require(:user).permit(:company_name, :phone, :email,
                                 address_attributes: [:id, :line1, :line2, :county, :town_city, :zip, :country_id],
                                 offices_attributes: [:id, :name, :contact_name, :daytime_phone, :evening_phone, :mobile,
                                                      :fax, :email, :website, :_destroy,
                                                      address_attributes: [:id, :line1, :line2, :county, :town_city, :zip, :country_id]],
                                 broker_info_attributes: [:id, :additional_email_raw, :website, :contact_name, :position,
                                                          :vat_number, :logo])
  end
end
