module MailerHelper
  def track_url(user_id, saved_search_id)
    saved_search_alert = SavedSearchAlertStatsGenerator.new(user_id, saved_search_id)

    url = "#{root_path(:only_path => false)}email/track/#{saved_search_alert.url}.png"

    raw("<img style=\"display: none\" src=\"#{url}\" alt=" " width=\"1\" height=\"1\">")
  end


  class SavedSearchAlertStatsGenerator
    attr_reader :url

    def initialize(user_id, saved_search_id)
      @saved_search_alert = SavedSearchAlert.create(create_params(user_id, saved_search_id))
      @url = generate_params(saved_search_alert.id)
    end

    private

    attr_reader :saved_search_alert

    def create_params(user_id, saved_search_id)
      saved_search = SavedSearch.find(saved_search_id)
      {
        user_id: user_id,
        saved_search_id: saved_search.id,
        alert_pointer_at_start: saved_search.first_found_boat_id
      }
    end

    def generate_params(saved_search_alert_id)
      "alert=#{saved_search_alert_id}"
    end

  end

end
