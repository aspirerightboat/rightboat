class Member::SavedSearchesController < Member::BaseController
  def index
    @saved_searches = current_user.saved_searches.order('id DESC').to_a
  end

  def create
    valid_params = params.permit(:year_min, :year_max, :price_min, :price_max, :length_min, :length_max,
                                 :length_unit, :manufacturer, :model, :currency, :ref_no, :q, :boat_type, :order,
                                 tax_status: [:paid, :unpaid], new_used: [:new, :used], country: [], category: [])

    SavedSearch.create_and_run(current_user, valid_params)

    render json: {}
  end

  def destroy
    @saved_search = SavedSearch.find(params[:id])
    @saved_search.destroy
  end

  def toggle
    @saved_search = SavedSearch.find(params[:id])
    @saved_search.update(alert: !@saved_search.alert)
  end
end