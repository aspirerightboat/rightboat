class InsurancesController < ApplicationController

  def create
    @insurance = current_user.insurances.new(insurance_params)

    if @insurance.save
      render json: {}, status: 200
    else
      render json: { errors: @insurance.errors }, status: 422
    end
  end

  private

  def insurance_params
    params.fetch(:insurance, {})
      .permit(:manufacturer_id, :model_id, :type_of_cover, :age_of_vessel, :country_id, :where_kept, :total_value,
              :currency, :years_no_claim)

  end
end