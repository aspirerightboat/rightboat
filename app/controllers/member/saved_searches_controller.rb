class Member::SavedSearchesController < Member::BaseController
  def index
    @saved_searches = current_user.saved_searches.to_a
  end

  def create
    valid_params = params.permit(:year_min, :year_max, :price_min, :price_max, :length_min, :length_max,
                                 :length_unit, :manufacturer_model, :currency, :ref_no)
    current_user.saved_searches.create!(valid_params)
    redirect_to({action: :index}, notice: 'Your search was saved')
  end
end