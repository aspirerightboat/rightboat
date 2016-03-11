namespace :error_events do

  desc 'Remove old error events'
  task remove_old: :environment do
    ErrorEvent.where('created_at < ?', 2.weeks.ago).delete_all
  end

end
