# Learn more: http://github.com/javan/whenever
# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

set :output, File.join(Whenever.path, 'log', 'cron.log')

require File.expand_path("#{File.dirname(__FILE__)}/environment")

Import.active.each do |import|
  every import.frequency_unit.to_sym, at: import.at_utc do
    runner "Import.find(#{import.id}).try_run_import!"
  end
end

every(1.minute) { runner 'LeadsApproveJob.new.perform' }
every(1.day, at: '22:10') { runner 'SavedSearchNoticesJob.new.perform' }
every(1.day, at: '1:00') { rake 'import:currency' }
every(1.day, at: '1:10') { rake 'rb_sitemap:refresh' }
every(12.hours, at: '6:20') { command 'sudo monit restart solr_rightboat' } # sometimes we have stale search results
every(1.day, at: '22:00') { rake 'import:download_eyb_feed' }
every(1.hour) { rake 'import:download_boatstream_feed' }
every(1.day, at: '8:00') { rake 'export:run_all' }
every(1.day, at: '23:00') { rake 'import:rearrange_imports' }
