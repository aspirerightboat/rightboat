class Member::SavedSearchesController < Member::BaseController
  def edit
    @saved_search = SavedSearch.find(params[:id])
    @current_length_unit = @saved_search.length_unit
  end

  def update
    @saved_search = SavedSearch.find(params[:id])
    permitted_params = permit_saved_search_params(params.require(:saved_search))

    if @saved_search.update(permitted_params)
      redirect_to member_user_notifications_path, notice: 'Your search was saved'
    else
      redirect_to member_user_notifications_path, alert: 'Something went wrong'
    end
  end

  def create
    SavedSearch.create_and_run(current_user, permit_saved_search_params(params))

    render json: {}
  end

  def destroy
    @saved_search = SavedSearch.find(params[:id])
    @saved_search.destroy
  end

  private

  def permit_saved_search_params(params)
    params[:manufacturers] = params[:manufacturers].split('-') if params[:manufacturers]&.is_a?(String)
    params[:models] = params[:models].split('-') if params[:models]&.is_a?(String)

    params.permit(:year_min, :year_max, :price_min, :price_max, :length_min, :length_max,
                  :length_unit, :currency, :ref_no, :q, :boat_type, :order,
                  tax_status: [:paid, :unpaid], new_used: [:new, :used],
                  manufacturers: [], models: [], countries: [])
  end
end
