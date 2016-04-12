module SavedSearchesMailerHelper
  def track_email_open_saved_searches(saved_searches_alert)
    url = saved_search_opened_email_trackings_url(token: saved_searches_alert.token, format: 'png')
    image_tag(url, style: 'display: none', size: '1x1')
  end
end
