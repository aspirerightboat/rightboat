class SavedSearchNoticesJob
  def perform
    all_searches = SavedSearch.where(alert: true)
                       .joins('JOIN user_alerts ON saved_searches.user_id = user_alerts.user_id')
                       .where(user_alerts: {saved_searches: true}).all
    all_searches_grouped = all_searches.group_by(&:user_id)
    sent_mails = 0
    all_searches_grouped.each do |user_id, saved_searches|
      searches = saved_searches.map do |ss|
        search = Rightboat::BoatSearch.new(ss.to_search_params)
        found_boats = search.retrieve_boats([], 5)
        if found_boats.any? && found_boats.first.id != ss.first_found_boat_id
          boat_ids = found_boats.map(&:id).split(ss.first_found_boat_id).first
          ss.first_found_boat_id = found_boats.first.id
          ss.save!
          [ss.id, boat_ids]
        end
      end
      searches.compact!

      if searches.any?
        UserMailer.saved_search_updated(user_id, searches).deliver_later
        sent_mails += 1
      end
    end
    [all_searches.size, all_searches_grouped.size, sent_mails]
  end
end
