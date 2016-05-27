# Learn more: http://github.com/javan/whenever
# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

set :output, File.join(Whenever.path, 'log', 'cron.log')

require File.expand_path("#{File.dirname(__FILE__)}/environment")

if Rails.env.production?
  Import.active.each do |import|
    every import.frequency_unit.to_sym, at: import.at_utc do
      rake "import:run[#{import.id}]"
    end
  end

  every(1.day, at: Import.active.last.approx_end_time) { rake 'saved_search_notifier:send_mails' }
end

every(2.minutes) { rake 'leads_approver:approve_recent' }
every(1.day, at: '1:00') { rake 'import:currency' }
every(1.day, at: '1:10') { rake 'rb_sitemap:refresh' }
every(12.hours, at: '6:20') { command 'sudo monit restart solr_rightboat' } if Rails.env.production? # sometimes we have stale search results
every(1.day, at: '22:00') { rake 'import:download_eyb_feed' }
every(1.hour) { rake 'import:download_boatstream_feed' }
every(1.day, at: '8:00') { rake 'export:run_all' } if Rails.env.production?
every(1.day, at: '23:00') { rake 'import:rearrange_imports' } if Rails.env.production?
every(1.day, at: '23:10') { rake 'error_events:remove_old' }
every(1.day, at: '23:15') { rake 'boat_pdfs:cleanup' }
every(1.day, at: '23:20') { rake 'boats_zips:cleanup' }
every(1.day, at: '23:55') { rake 'inventory_trend:store' }
