class BrokerAreaController < ApplicationController
  before_action :require_broker_user

  def show
    rel = current_user.enquiries.includes(boat: [:manufacturer, :model]).order('id DESC')
    @pending_leads = Enquiry.where(status: %w(pending quality_check)).merge(rel).page(params[:page]).per(15)
    @history_leads = Enquiry.where(status: %w(approved rejected invoiced)).merge(rel).page(params[:page2]).per(15)
  end

  # def my_leads
  # end
end