class Member::SavedSearchesController < Member::BaseController
  def edit
    @saved_search = SavedSearch.find_by(id: params[:id])
  end

  def update
    @saved_search = SavedSearch.find_by(id: params[:id])

    if @saved_search.update(update_params)
      redirect_to member_user_notifications_path, notice: 'Your search was saved'
    else
      redirect_to member_user_notifications_path, notice: 'Something went wrong'
    end
  end

  def create
    params[:country] = params.delete(:countries).split('-') if params[:countries]
    params[:models] = params[:models].split('-') if params[:models]

    SavedSearch.create_and_run(current_user, create_params)

    render json: {}
  end

  def destroy
    @saved_search = SavedSearch.find(params[:id])
    @saved_search.destroy
  end

  private

  def create_params
    params.permit(:year_min, :year_max, :price_min, :price_max, :length_min, :length_max,
                  :length_unit, :manufacturer, :model, :currency, :ref_no, :q, :boat_type, :order,
                  tax_status: [:paid, :unpaid], new_used: [:new, :used], country: [], category: [], models: [])
  end

  def update_params
    params.require(:saved_search).permit(:year_min, :year_max, :price_min, :price_max, :length_min, :length_max,
                  :length_unit, :manufacturer, :model, :currency, :ref_no, :q, :boat_type, :order,
                  tax_status: [:paid, :unpaid], new_used: [:new, :used], country: [], category: [], models: [])
  end
end
