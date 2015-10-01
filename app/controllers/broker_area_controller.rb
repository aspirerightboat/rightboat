class BrokerAreaController < ApplicationController
  before_action :require_broker_user

  def show
    redirect_to({action: :getting_started})
  end

  def getting_started
  end

  def details
    current_user.build_address
  end

  def update_details
  end

  def preferences
  end

  def update_preferences
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
end