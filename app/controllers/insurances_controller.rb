class InsurancesController < ApplicationController
  before_action :authenticate_user!

  def load_popup
    render json: {show_popup: render_to_string(partial: 'insurances/insurance_popup', formats: [:html])}
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
    params.require(:insurance).permit(:manufacturer_id, :model_id, :type_of_cover, :age_of_vessel,
                                      :country_id, :where_kept, :total_value, :currency, :years_no_claim)
  end

end
