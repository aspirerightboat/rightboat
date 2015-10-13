require 'mechanize'
require 'nokogiri'

module Rightboat
  module Imports
    class Base
      MAX_RETRIES = 5

      include Utils

      attr_accessor :scraped_boats, :missing_attrs, :exit_worker
      attr_reader :import_trail

      def self.source_types
        %w(openmarine yachtworld ancasta boatsandoutboards charleswatson eyb yatco)
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

        @images_count = 0
      end

      def logger
        @logger ||= begin
          dir = FileUtils.mkdir_p("#{Rails.root}/log/imports").first
          @log_path = "#{dir}/import-log-#{@import.id}-#{@import.import_type}--#{Time.current.strftime('%F--%H-%M-%S')}.log"
          Logger.new(@log_path)
        end
      end

      def log(str)
        logger.info str
        puts str if Rails.env.development?
      end

      def log_error(str, import_msg = nil)
        log str
        @import_trail.update_attribute(:error_msg, import_msg || str)
      end

      def run
        logger # init logger
        Rails.logger = logger
        @import_trail = ImportTrail.create(import: @import, log_path: @log_path)
        @import.update_attribute(:last_import_trail, @import_trail)
        log "Started param=#{@import.param.inspect} threads=#{@thread_count} use_proxy=#{@use_proxy} pid=#{@import.pid}"

        begin
          threaded_run
        rescue Exception => e
          log_error "#{e.class.name} Error: #{e.message}\n#{e.backtrace.join("\n")}", 'Unexpected error'
          @import_trail.touch(:finished_at)
          raise e
        end
      end

      def threaded_run
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
                if (boat = process_job(job))
                  boat.user = @user
                  boat.import = @import
                end
              rescue StandardError => e
                log_error "#{e.class.name} Error: #{e.message}", 'Process Error'
                ImportMailer.process_error(e, @import, job).deliver_now
              end
              @_writer_mutex.synchronize {@scraped_boats << boat if boat}
            end
          end
        end

        enqueue_jobs
        _end_q = true

        threads.each(&:join)

        if @missing_attrs.present?
          log "===> MISSING ATTRIBUTES: #{@missing_attrs.inspect}"
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
        @import_trail.boats_count = @scraped_boats.size

        remove_old_boats

        if @scraped_boats.blank?
          log_error 'Import Blank'
          ImportMailer.import_blank(@import).deliver_now
          return
        end

        @scraped_boats.each do |source_boat|
          break if @exit_worker
          begin
            success = source_boat.save
            if success
              log "Boat saved. images_count=#{source_boat.images_count || 0}"
              @import_trail.images_count += source_boat.images_count
              source_boat.new_boat ? @import_trail.new_count += 1 : @import_trail.updated_count += 1
            else
              log_error source_boat.error_msg, 'Save Boat Error'
              @import_trail.not_saved_count += 1
            end
            @import_trail.save
          rescue
            log_error 'Invalid Boat'
            ImportMailer.invalid_boat(source_boat).deliver_now
            next
          end
        end

        @import_trail.finished_at = Time.current
        @import_trail.save!
        @import.touch(:last_ran_at)
        log 'Finished'
      rescue Exception => e
        log_error "===> PROCESS RESULT ERROR. #{e.class.name}: #{e.message}", 'Process Result Error'
        ImportMailer.process_result_error(e, @import).deliver_now
      end

      def remove_old_boats
        old_source_ids = @user.boats.map{|b|b.source_id.to_s}
        scraped_source_ids = scraped_boats.map{|b|b.source_id.to_s}
        delete_source_ids = old_source_ids - scraped_source_ids
        delete_source_ids.reject!(&:blank?)

        delete_boats = @user.boats.select { |boat| boat.source_id.in?(delete_source_ids) }
        delete_boats.each do |boat|
          break if @exit_worker
          log "Deleting Boat id=#{boat.id} source_id=#{boat.source_id}"
          boat.destroy
        end

        @import_trail.deleted_count = delete_boats.size
      end

      def advert_url(url, scheme='http')
        return unless url
        uri = URI(url)
        uri.host ||= host
        uri.scheme ||= scheme
        uri.to_s
      end
    end
  end
end