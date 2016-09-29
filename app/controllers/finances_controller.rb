class FinancesController < ApplicationController

  def load_popup
    render json: {show_popup: render_to_string(partial: 'finances/finance_popup', formats: [:html])}
  end

  def create
    @finance = current_user.finances.new(finance_params)

    if @finance.save
      StaffMailer.new_finance(@finance.id).deliver_later
      render json: {show_popup: render_to_string(partial: 'finances/finance_result_popup', formats: [:html])}
    else
      render json: @finance.errors.full_messages, root: false, status: 422
    end
  end

  private

  def finance_params
    params.require(:finance).permit(:manufacturer_id, :model_id, :age_of_vessel, :country_id,
                                    :price, :price_currency, :loan_amount, :loan_amount_currency)
  end

end
