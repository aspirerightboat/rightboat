#!/usr/bin/env ruby

require 'clockwork'
require './config/boot'
require './config/environment'

module DBBackedClockwork
  include Clockwork

  configure do |config|
    config[:logger] = Logger.new('log/clockwork.log', 5, 2.megabytes)
    config[:sleep_timeout] = 1.second
    config[:tz] = 'UTC' # http://tzinfo.rubyforge.org
    config[:thread] = false # multithreading ignores job when count of threads reached to max, disable threading for safe
    config[:max_threads] = 15
  end

  every 1.minute, 'update import events' do
    import_events = events.select { |e| e.respond_to?(:import_id) }
    imports = Import.where(id: import_events.map(&:import_id)).to_a
    import_events.each do |event|
      event.refresh_from_import(imports.find { |i| i.id == event.import_id })
    end

    Import.active.each do |import|
      events << ImportEvent.new(import) if import_events.none? { |event| event.import_id == import.id }
    end
  end

  every 1.minute, 'approve old pending leads', thread: true do
    LeadsApproveJob.new.perform
  end

  every 1.day, 'send saved search notifications', at: '22:10', thread: true do
    SavedSearchNoticesJob.new.perform
  end

  every 1.day, 'update currency', at: '1:00' do
    system 'bundle exec rake import:currency &'
  end

  every 1.day, 'sitemap_refresh', at: '1:10' do
    system 'bundle exec rake rb_sitemap:refresh &'
  end

  every 1.day, 'restart_solr', at: '6:20' do # sometimes we have stale search results
    system 'sudo monit restart solr_rightboat &'
  end

  every 1.day, 'download eyb xml', at: '22:00', thread: true do
    res = `/bin/bash eyb.sh`
    ExpertMailer.download_feed_error('Eyb').deliver_now if res !~ /Success\Z/
  end

  every 1.hour, 'download boatstream xml' do
    system 'bundle exec rake import:download_boatstream_feed &'
  end

  every 1.day, 'export openmarine boats', at: '8:00' do
    system 'bundle exec rake export:run_all &'
  end

  # get the manager object
  def self.manager
    Clockwork.instance_variable_get(:@manager)
  end

  # get the events array
  def self.events
    manager.instance_variable_get(:@events)
  end

  class ImportEvent < Clockwork::Event
    attr_accessor :import_id, :updated_at

    def initialize(import)
      handler = Proc.new { |job, _time|
        if job =~ /import-(\d+)/
          Import.find($1).try_run_import_rake!(false)
        end
      }

      self.import_id = import.id
      self.updated_at = import.updated_at

      super(DBBackedClockwork.manager, import.frequency, "import-#{import.id}",
            handler, at: import.at.presence, tz: import.tz)
    end

    # find the job in the database and update or remove it if necessary
    def refresh_from_import(import)
      (remove; return) if !import

      if !import.active
        import.stop_or_kill! if import.process_running?
        remove
      elsif import.updated_at != updated_at
        remove
        DBBackedClockwork.events << ImportEvent.new(import)
      end
    end

    # remove this event from the events array
    def remove
      DBBackedClockwork.events.reject! { |e| e.respond_to?(:import_id) && e.import_id == import_id }
    end
  end
end

