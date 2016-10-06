class Rightboat::SavedSearchNotifier
  attr_reader :logger

  def send_mails
    start_logging
    wait_for_new_boat_images

    all_searches = SavedSearch.where(alert: true)
                       .joins('JOIN user_alerts ON saved_searches.user_id = user_alerts.user_id')
                       .where(user_alerts: {saved_searches: true}).to_a
    all_searches_grouped = all_searches.group_by(&:user_id)
    logger.info "#{all_searches.size} saved searches found for #{all_searches_grouped.size} users"

    sent_mails = 0
    all_searches_grouped.each do |user_id, saved_searches|
      searches = saved_searches.map do |ss|
        search_query = ss.to_search_params.merge!(order: 'created_at_desc')
        found_boats = Rightboat::BoatSearch.new.do_search(params: search_query, includes: [], per_page: 5).results
        if found_boats.any? && found_boats.first.id > (ss.first_found_boat_id || 0)
          boat_ids = found_boats.map(&:id)
          boat_ids.select! { |id| id > ss.first_found_boat_id } if ss.first_found_boat_id
          ss.first_found_boat_id = found_boats.first.id
          ss.save!
          [ss.id, boat_ids] if boat_ids.any?
        end
      end
      searches.compact!

      if searches.any?
        saved_search_infos = searches.map { |id, boat_ids| {id: id, boat_ids: boat_ids} }
        saved_searches_alert = SavedSearchesAlert.create!(user_id: user_id, saved_search_infos: saved_search_infos)
        UserMailer.saved_search_updated(user_id, searches, saved_searches_alert.id).deliver_later
        sent_mails += 1
      end
    end
    logger.info "#{sent_mails} emails sent. Finished"

    [all_searches.size, all_searches_grouped.size, sent_mails]
  rescue StandardError => e
    logger&.error "#{e.class.name}: #{e.message}\n#{e.backtrace.join("\n")}"
    Rightboat::CleverErrorsNotifier.try_notify(e, nil, nil, where: self.class.name)
    raise e
  end

  private

  def wait_for_new_boat_images
    timeout = Time.current + 2.hours

    while Delayed::Job.where(queue: 'import_images', priority: 0).exists? && Time.current < timeout
      logger.info 'Wait for high priority import images'
      sleep 5.minutes
    end
  end

  def start_logging
    cleanup_old_logs
    init_logger
    logger.info 'Started'
  end

  def cleanup_old_logs
    month_ago = 1.month.ago

    Dir[log_dir + '/*'].each do |file|
      if File.mtime(file) < month_ago
        FileUtils.rm(file)
      end
    end
  end

  def log_dir
    "#{Rails.root}/log/saved_search_notifications"
  end

  def init_logger
    FileUtils.mkdir_p(log_dir)
    @logger = Logger.new("#{log_dir}/job-#{Time.current.strftime('%F--%H-%M-%S')}.log")
  end
end
