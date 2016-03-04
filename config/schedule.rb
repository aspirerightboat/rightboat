# Learn more: http://github.com/javan/whenever
# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

set :output, File.join(Whenever.path, 'log', 'cron.log')

require File.expand_path("#{File.dirname(__FILE__)}/environment")

Import.active.each do |import|
  every import.frequency_unit, at: import.at_utc do
    runner "Import.find(#{import.id}).try_run_import!"
  end
end

every 1.minute do
  runner 'LeadsApproveJob.new.perform'
end

every 1.day, at: '22:10' do
  runner 'SavedSearchNoticesJob.new.perform'
end

every 1.day, at: '1:00' do
  rake 'rake import:currency'
end

every 1.day, at: '1:10' do
  rake 'rake rb_sitemap:refresh'
end

every 12.hours, at: '6:20' do # sometimes we have stale search results
  command 'sudo monit restart solr_rightboat'
end

every 1.day, at: '22:00' do
  rake 'import:download_eyb_feed'
end

every 1.hour do
  rake 'import:download_boatstream_feed'
end

every 1.day, at: '8:00' do
  rake 'rake export:run_all'
end
