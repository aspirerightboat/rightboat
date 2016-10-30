class InsurancesController < ApplicationController
  before_action :authenticate_user!, except: [:load_login_popup]

  def load_popup
    render json: {show_popup: render_to_string(partial: 'insurances/insurance_popup', formats: [:html])}
  end

  def load_login_popup
    render json: {show_popup: render_to_string(partial: 'insurances/login_popup', formats: [:html])}
  end

  def create
    @insurance = current_user.insurances.new(insurance_params)

    if @insurance.save
      StaffMailer.new_insurance(@insurance.id).deliver_later
      render json: {show_popup: render_to_string(partial: 'insurances/insurance_result_popup', formats: [:html])}
    else
      render json: @insurance.errors.full_messages, root: false, status: 422
    end
  end

  private

  def insurance_params
    params.require(:insurance).permit(:manufacturer_id, :model_id, :full_name, :contact_number, :email,
                                      :craft_year, :renewal_date, :total_value, :currency)
  end

end
