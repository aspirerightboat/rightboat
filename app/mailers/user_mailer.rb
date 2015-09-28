class UserMailer < ApplicationMailer
  layout 'mailer'

  def saved_search_updated(user_id, searches)
    @user = User.find(user_id)

    @searches = searches.map { |saved_search_id, boat_ids|
      saved_search = SavedSearch.find_by(id: saved_search_id)
      next if !saved_search
      [saved_search, Boat.where(id: boat_ids).includes(:manufacturer, :model).to_a]
    }.compact

    mail(to: @user.email, subject: 'New Search Listings Alert - Rightboat')
  end

end
