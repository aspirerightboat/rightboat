class UserMailerPreview < ActionMailer::Preview

  def saved_search_updated
    searches = SavedSearch.limit(2).pluck(:id).map.with_index do |ss_id, i|
      [ss_id, Boat.not_deleted.limit((i+1)*2).offset(i*5).pluck(:id)]
    end
    UserMailer.saved_search_updated(User.last.id, searches, SavedSearchesAlert.last.id)
  end

  def email_confirmation
    UserMailer.email_confirmation(User.last.id)
  end

  def boat_status_changed
    UserMailer.boat_status_changed(User.last.id, Boat.last.id, 'deleted', 'favourite')
  end

  def boat_detail
    UserMailer.boat_detail(User.last.id, Boat.last.id)
  end
end
