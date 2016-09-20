class Member::SavedSearchesController < Member::BaseController
  def new
    @saved_search = SavedSearch.new
    render :edit
  end

  def edit
    @saved_search = SavedSearch.find(params[:id])
    @current_length_unit = @saved_search.length_unit
  end

  def update
    saved_search = SavedSearch.find(params[:id])
    saved_search.safe_assign_params(params.require(:saved_search))
    saved_search.save!
    UserActivity.create_search_record(hash: saved_search.to_succinct_search_hash, user: current_customer)

    redirect_to member_user_notifications_path, notice: 'Your saved search has been updated'
  end

  def create
    saved_search = SavedSearch.safe_create(current_customer, params.require(:saved_search))

    if saved_search
      UserActivity.create_search_record(hash: saved_search.to_succinct_search_hash, user: current_customer)
      session[:ss_created_conversion] = 1
      redirect_to member_user_notifications_path, notice: 'Your search has been saved'
    else
      redirect_to member_user_notifications_path, alert: 'Something went wrong'
    end
  end

  def create_from_search
    saved_search = SavedSearch.safe_create(current_customer, params)
    if saved_search
      UserActivity.create_search_record(hash: saved_search.to_succinct_search_hash, user: current_customer)
    end
    render json: {google_conversion: render_to_string(partial: 'shared/google_saved_search_conversion')}
  end

  def destroy
    @saved_search = SavedSearch.find(params[:id])
    @saved_search.destroy
  end

  def toggle_alert
    saved_search = SavedSearch.find(params[:id])
    saved_search.update(alert: !saved_search.alert)

    saved_search.ensure_ss_alerts_enabled if saved_search.alert

    render json: {alert: saved_search.alert}
  end

end
