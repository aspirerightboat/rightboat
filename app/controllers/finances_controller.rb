class FinancesController < ApplicationController

  def create
    @finance = current_user.finances.new(finance_params)

    if @finance.save
      render json: {}, status: 200
    else
      render json: @finance.errors.full_messages, root: false, status: 422
    end
  end

  private

  def finance_params
    params.fetch(:finance, {})
      .permit(:manufacturer_id, :model_id, :age_of_vessel, :country_id, :price, :price_currency, :loan_amount, :loan_amount_currency)
  end
end