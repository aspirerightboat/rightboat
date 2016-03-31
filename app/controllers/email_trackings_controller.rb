class EmailTrackingsController < ApplicationController

  def saved_search_opened
    saved_search_alert = SavedSearchesAlert.find_by(token: params[:token])

    if saved_search_alert
      saved_search_alert.touch(:opened_at) if !saved_search_alert.opened_at
      head :ok
    else
      head :bad_request
    end
  end

end
