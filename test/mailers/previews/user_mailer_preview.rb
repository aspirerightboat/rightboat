class UserMailerPreview < ActionMailer::Preview

  def saved_search_updated
    UserMailer.saved_search_updated(User.last.id, [SavedSearch.last.id])
  end

  def email_confirmation
    UserMailer.email_confirmation(User.last.id)
  end

  def new_sell_request
    UserMailer.new_sell_request(Boat.last.id, Boat::SELL_REQUEST_TYPES.sample)
  end

  def favourite_boat_status_changed
    UserMailer.favourite_boat_status_changed(User.last.id, Boat.last.id, 'deleted')
  end
end
