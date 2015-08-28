require 'mechanize'
require 'nokogiri'

module Rightboat
  module Imports
    class Base
      MAX_RETRIES = 5

      include Utils

      attr_accessor :scraped_boats, :missing_attrs, :exit_worker

      def self.source_types
        ['openmarine', 'yachtworld', 'ancasta', 'boatsandoutboards']
      end

      def initialize(import)
        import.param.each do |key, value|
          instance_variable_set "@#{key}", value
        end
        @user = import.user
        @import = import
        @use_proxy = import.use_proxy?

        @_agent = Mechanize.new
        @_agent.user_agent_alias = 'Windows IE 7'
        @_agent.ssl_version = 'SSLv3'
        @_agent.keep_alive = false
        @_agent.max_history = 3
        @_agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
        @_agent.read_timeout = 120
        @_agent.open_timeout = 120

        @scraped_boats = []
        @thread_count = import.threads

        @_writer_mutex = Mutex.new

        @_queue_mutex = Mutex.new
        @_queue = Queue.new
      end

      def run
        _end_q = false
        threads = []

        # trap('SIGINT') { @exit_worker = true; _end_q = true; @_queue.clear }

        @thread_count.to_i.times do
          threads << Thread.new do
            while true
              job = nil
              @_queue_mutex.synchronize do
                job = @_queue.pop(true) rescue nil
              end

              break if @exit_worker || (_end_q && !job)
              unless job
                sleep 3
                next
              end

              begin
                if boat = process_job(job)
                  boat.user = @user
                  boat.import = @import
                end
              rescue Exception => e
                # TODO: messaging system for exception
                raise e
              end
              @_writer_mutex.synchronize {@scraped_boats << boat if boat}
            end
          end
        end

        enqueue_jobs
        _end_q = true

        threads.each(&:join)

        unless @missing_attrs.blank?
          puts "******* MISSING **********"
          puts @missing_attrs
        end

        process_result unless @exit_worker
      end

      # set validate options for each param
      #  e.g. require office_id and only accepts digits
      #       { office_id: [:presence, /\d+/] }
      def self.validate_param_option
        {}
      end

      def self.params
        self.validate_param_option.keys
      end

      private

      def enqueue_job(job)
        @_queue_mutex.synchronize do
          @_queue.push(job.clone)
        end
      end

      def get(url, params = [], referer = nil, headers = {})
        retry_cnt = 0
        begin
          @_agent.cookie_jar.clear!
          @_agent.get(url, params, referer, headers)
        rescue Mechanize::ResponseCodeError => e
          retry_cnt += 1
          retry if retry_cnt < MAX_RETRIES
          raise e
        end
      end

      def basic_auth(user, password)
        @_agent.auth(user, password)
      end

      def process_result
        remove_old_boats

        if @scraped_boats.blank?
          # TODO: notifiy error for no boat scraping
          return
        end

        @scraped_boats.each do |source_boat|
          break if @exit_worker
          source_boat.save
        end

        @import.update_column :last_ran_at, Time.now
      rescue Exception => e
        # TODO notify error for exception
        raise e
      end

      def remove_old_boats
        deleted_source_ids = @user.boats.map{|b|b.source_id.to_s} - @scraped_boats.map{|b|b.source_id.to_s}
        deleted_source_ids.each do |source_id|
          break if @exit_worker
          next if source_id.blank?
          boat = Boat.find_by_source_id(source_id)
          puts "Deleting #{boat.id} - #{source_id}"
          boat.destroy
        end
      end

    end
  end
end