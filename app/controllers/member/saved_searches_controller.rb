class Member::SavedSearchesController < Member::BaseController
  def index
    @saved_searches = current_user.saved_searches.order('id DESC').to_a
  end

  def create
    valid_params = params.permit(:year_min, :year_max, :price_min, :price_max, :length_min, :length_max,
                                 :length_unit, :manufacturer_model, :currency, :ref_no, :q, :boat_type, :order,
                                 tax_status: [:paid, :unpaid], new_used: [:new, :used], country: [], category: [])

    ss = current_user.saved_searches.new(valid_params)

    @first_boat = Rightboat::BoatSearch.new.do_search(params, per_page: 1).results.first
    ss.first_found_boat_id = @first_boat.try(:id)

    ss.save!

    render json: {}
  end

  def destroy
    saved_search = SavedSearch.find(params[:id])
    saved_search.destroy

    redirect_to member_saved_searches_path
  end

  def toggle
    SavedSearch.where(id: params[:id]).update_all('alert = NOT alert')

    redirect_to member_saved_searches_path
  end
end