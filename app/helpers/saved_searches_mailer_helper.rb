module SavedSearchesMailerHelper
  def saved_searches_mail_track_url(user_id, saved_search_ids)
    saved_search_alert = SavedSearchesAlert.create({user_id: user_id, saved_search_ids: saved_search_ids})

    url = "#{root_url}email/track/alert_id=#{saved_search_alert.id}.png"
    image_tag(url, style: "display: none")
  end

end
