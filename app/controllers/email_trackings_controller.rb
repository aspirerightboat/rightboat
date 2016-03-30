class EmailTrackingsController < ApplicationController
  def open
    saved_search_alert = SavedSearchesAlert.find(params[:alert_id])
    saved_search_alert.update(opened_at: Time.zone.now)
    render nothing: true
  end
end
