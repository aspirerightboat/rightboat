class UserMailer < ApplicationMailer
  layout 'mailer'

  def saved_search_updated(user_id, searches)
    @user = User.find(user_id)

    @searches = searches.map { |saved_search_id, boat_ids|
      saved_search = SavedSearch.find_by(id: saved_search_id)
      next if !saved_search
      [saved_search, Boat.where(id: boat_ids).includes(:manufacturer, :model).to_a]
    }.compact

    to_email = STAGING_EMAIL || @user.email
    mail(to: to_email, subject: 'New Search Listings Alert - Rightboat')
  end

  def email_confirmation(user_id)
    @user = User.find(user_id)
    @confirm_href = confirm_email_url(user: user_id, token: @user.confirm_email_token)

    to_email = STAGING_EMAIL || @user.email
    mail(to: to_email, subject: 'Confirm your email - Rightboat')
  end

  def new_sell_request(boat_id, request_type)
    @boat = Boat.find(boat_id)
    @user = @boat.user
    @request_type = request_type

    mail(to: 'info@rightboat.com', subject: 'New sell my boat request - RightBoat')
  end
end