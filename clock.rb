#!/usr/bin/env ruby

require 'clockwork'
require './config/boot'
require './config/environment'

module DBBackedClockwork
  include Clockwork

  configure do |config|
    config[:sleep_timeout] = 1
    config[:tz] = 'UTC' # http://tzinfo.rubyforge.org
    config[:thread] = false # multithreading ignores job when count of threads reached to max, disable threading for safe
    config[:max_threads] = 15
  end

  every 1.minute, 'update jobs' do
    db_events.each do |event|
      event.update_from_db
    end

    # add database events
    Import.active.each do |e|
      events << DBBackedEvent.new(e) unless db_events.map(&:id).include?(e.id)
    end
  end

  every 1.minute, 'approve old pending leads' do
    LeadsApproveJob.new.perform
  end

  every 1.day, 'send saved search notifications', at: '22:00' do
    SavedSearchNoticesJob.new.perform
  end

  every 1.day, 'update currency', at: '1:00' do
    `bundle exec rake import:currency`
  end

  every 1.day, 'sitemap_refresh', at: '1:10' do
    `bundle exec rake rb_sitemap:refresh`
  end

  every 1.day, 'restart_solr', at: '6:20' do # sometimes we have stale search results
    `sudo monit restart solr_rightboat`
  end

  every 1.day, 'download eyb xml', at: '22:00' do
    `/bin/bash eyb.sh`
  end

  # get the manager object
  def self.manager
    Clockwork.instance_variable_get(:@manager)
  end

  # get the events array
  def self.events
    manager.instance_variable_get(:@events)
  end

  # get the db backed events from the events array
  # NOTE: this creates a new array and is not associated to the "official" events instance variable
  def self.db_events
    events.reject{|e| !e.respond_to?(:id) }
  end

  class DBBackedEvent < Clockwork::Event
    # add @id tagged to DB to update a job
    attr_accessor :id, :updated_at

    def initialize(event)
      handler = Proc.new { |job, time|
        if job =~ /import\-.*\[\d+\]/
          id = job[/\[(\d+)\]$/, 1].to_i
          begin
            import = Import.find(id)
            unless import.running?
              Rails.logger.info("[IMPORT] --- Start importing #{job} at #{time}")
              import.run!
            end
          rescue StandardError => e
            Rails.logger.info("[IMPORT] --- Error #{e.message}")
          end
        end
      }

      self.id = event.id
      self.updated_at = event.updated_at

      at = event.at.blank? ? nil : event.at
      super(DBBackedClockwork.manager, event.frequency, "import-#{event.import_type}[#{event.id}]", handler, at: at, tz: event.tz)
    end

    # find the job in the database and update or remove it if necessary
    def update_from_db
      begin
        job = Import.find(id)
        if !job.active
          job.nonblock_stop!
          self.remove
        elsif job.updated_at != updated_at
          self.remove
          DBBackedClockwork.events << DBBackedEvent.new(job)
        end
      rescue ActiveRecord::RecordNotFound
        # remove the event
        self.remove
      end
    end

    # remove this event from the events array
    def remove
      DBBackedClockwork.events.reject!{|e| e.id == id rescue false}
    end
  end
end

