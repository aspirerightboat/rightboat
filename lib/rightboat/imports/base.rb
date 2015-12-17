require 'mechanize'
require 'nokogiri'
require 'rightboat/imports/source_boat' # to fix "Circular dependency detected while autoloading constant" error while running multithreaded import

module Rightboat
  module Imports
    class Base
      MAX_RETRIES = 5

      include Utils

      attr_reader :jobs_mutex

      def initialize(import)
        @import = import
        @import_trail = ImportTrail.create(import: @import)
        init_logger
        @import_trail.update(log_path: @log_path)
        @import.update(last_import_trail: @import_trail, pid: Process.pid, last_ran_at: Time.current)
      end

      def run
        starting
        threaded_run
        finishing
      rescue StandardError => e # SystemExit, Interrupt
        log_ex e, 'Unexpected Error'
        raise e
      ensure
        @import_trail.touch(:finished_at)

        if @import_trail.error_msg
          ImportMailer.importing_errors(@import_trail.id).deliver_now
        end
      end

      def starting
        @import.param.each { |key, value| instance_variable_set("@#{key}", value) }

        init_mechanize_agent

        @jobs_queue = Queue.new
        @jobs_mutex = Mutex.new

        @user = @import.user
        @old_source_ids = @user.boats.pluck(:source_id)
        @scraped_source_ids = []

        Rails.application.eager_load! # fix "Circular dependency error" while running with multiple threads

        log "Started param=#{@import.param.inspect} threads=#{@import.threads} pid=#{@import.pid}"
      end

      def threaded_run
        trap('SIGINT') { @exit_worker = true }

        threads = safe_threads_count.times.map do
          Thread.new do
            begin
              loop do
                job = (@jobs_queue.pop(true) rescue nil)

                parse_and_save_boat(job) if job

                break if @exit_worker || (@all_jobs_enqueued && !job)
                sleep(2.seconds) if !job
              end
            rescue StandardError => e
              log_ex e, 'Thread Error'
              raise e # exception will be swallowed by thread and not passed to main thread
            ensure
              ActiveRecord::Base.connection.close
            end
          end
        end

        enqueue_jobs
        @all_jobs_enqueued = true

        threads.each(&:join)
      end

      def finishing
        (log 'Terminated'; return) if @exit_worker

        if @scraped_source_ids.none?
          log_error 'Import Blank'

          return if @import_trail.error_msg.present?
        end

        if @jobs_queue.empty? # all jobs processed
          remove_old_boats
        end

        boats_count = @user.boats.not_deleted.count
        log "updating boats count cache #{boats_count}"
        @user.update boats_count: boats_count

        log 'Finished'
      end

      def safe_threads_count
        threads_count = @import.threads.to_i
        available_db_conn_count = ActiveRecord::Base.connection_pool.size - ActiveRecord::Base.connection_pool.connections.size
        raise 'No free DB connections left' if available_db_conn_count <= 0

        if available_db_conn_count < threads_count
          log "Not enough DB connections (#{available_db_conn_count} < #{threads_count}). Please increase pool size in database.yml"
          available_db_conn_count
        else
          threads_count
        end
      end

      def self.import_types
        @import_types ||= Dir["#{Rails.root}/lib/rightboat/imports/sources/*"].map { |path| File.basename(path, '.*') }
      end

      # def self.import_classes
      #   @@import_classes ||= import_types.map { |type| Sources.const_get(type.camelcase) }
      # end

      # set validate options for each param
      #  e.g. require office_id and only accepts digits
      #       { office_id: [:presence, /\d+/] }
      def self.validate_param_option
        {}
      end

      def self.params
        validate_param_option.keys
      end

      def enqueue_job(job)
        @jobs_queue.push(job.clone)
      end

      # log levels: :debug, :info, :warn, :error, :fatal
      def log(str, kind = :info)
        @logger.send kind, str
        puts str if Rails.env.development?
      end

      def log_error(short_msg, debug_info = nil)
        log "#{short_msg}. #{debug_info}", :error
        @import_trail.update_attribute(:error_msg, short_msg) if !@import_trail.error_msg
      end

      def log_warning(short_msg, debug_info = nil)
        log "#{short_msg}. #{debug_info}", :warn
        @import_trail.update_attribute(:warning_msg, short_msg) if !@import_trail.warning_msg
      end

      def log_ex(e, short_msg)
        backtrace_lines_count = Rails.env.development? ? 50 : 10
        log_error short_msg, "#{e.class.name} Error: #{e.message}\n#{e.backtrace.first(backtrace_lines_count).join("\n")}"
      end

      private

      def get(url, params = [], referer = nil, headers = {'Accept-Encoding' => 'gzip, deflate'})
        retry_cnt = 0
        begin
          @agent.cookie_jar.clear!
          @agent.get(url, params, referer, headers)
        rescue Mechanize::ResponseCodeError => e
          retry_cnt += 1
          retry if retry_cnt < MAX_RETRIES
          raise e
        end
      end

      def basic_auth(user, password)
        @agent.auth(user, password)
      end

      def parse_and_save_boat(job)
        boat = safe_parse_boat(job)
        (log 'Not saved. Move to next'; return) if !boat
        @jobs_mutex.synchronize { @scraped_source_ids << boat.source_id }
        safe_save_boat(boat)
      end

      def safe_parse_boat(job)
        @skip_thread_parsing_boat ? job : process_job(job)
      rescue StandardError => e
        log_ex e, 'Parse Error'
        nil
      end

      def safe_save_boat(source_boat)
        increment_stats = []
        source_boat.user = @user
        source_boat.import = @import
        source_boat.import_base = self

        success = source_boat.save
        if success
          log "Boat saved. id=#{source_boat.target.id} source_id=#{source_boat.source_id} images_count=#{source_boat.images_count || 0}"
          increment_stats << [source_boat.new_record ? 'new_count' : 'updated_count', 1]
          increment_stats << ['images_count', source_boat.images_count]
        else
          log_error 'Save Boat Error', source_boat.error_msg
          increment_stats << ['not_saved_count', 1]
        end

        increment_stats << ['boats_count', 1]
        ImportTrail.where(id: @import_trail.id).update_all(increment_stats.map { |col, cnt| "#{col} = #{col} + #{cnt}" }.join(', '))
      rescue StandardError => e
        log_ex e, 'Save Boat Error'
      end

      def remove_old_boats
        delete_source_ids = (@old_source_ids - @scraped_source_ids).reject(&:blank?)
        delete_boats = @user.boats.not_deleted.where(source_id: delete_source_ids).to_a
        delete_boats.each do |boat|
          log "Deleting Boat id=#{boat.id} source_id=#{boat.source_id}"
          boat.destroy
        end

        @import_trail.update_attribute(:deleted_count, delete_boats.size)
      end

      def init_logger
        dir_path = Rails.root + "#{'../../shared/' if !Rails.env.development?}log/imports/#{Time.current.strftime('%F')}"
        dir = FileUtils.mkdir_p(dir_path).first
        @log_path = "#{dir}/import-log-#{@import_trail.id}-#{@import.id}-#{@import.import_type}-#{Time.current.strftime('%H-%M-%S')}.log"
        @logger = Logger.new(@log_path)
        @logger.level = 0 # log all
      end

      def init_mechanize_agent
        @agent = Mechanize.new
        @agent.user_agent_alias = 'Mechanize'
        @agent.ssl_version = 'SSLv3'
        @agent.keep_alive = false
        @agent.max_history = 3
        @agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
        @agent.read_timeout = 120
        @agent.open_timeout = 120

        # fix issue when importing feed http://exports.boatshop24.com/om/1364
        # see: http://stackoverflow.com/questions/18807599/problems-with-text-csv-content-encoding-utf-8-in-ruby-mechanize
        func = lambda do |a, uri, resp, body_io|
          resp['Content-Encoding'] = 'none' if resp['Content-Encoding'].to_s == 'UTF-8'
        end
        @agent.content_encoding_hooks << func
      end

      def advert_url(url, scheme='http')
        return unless url
        uri = URI(url)
        uri.host ||= host
        uri.scheme ||= scheme
        uri.to_s
      end

      def convert_unit(value, unit)
        return if unit.blank? || value.is_a?(String) && value =~ /^[0.]+$/

        case unit.downcase
        when 'feet', 'ft', 'f' then value.to_f.ft_to_m.round(2)
        when /\A(?:metres?|meters?|m)\z/ then value.to_f.round(2)
        when 'kg', 'kgs', 'k' then value.to_f.round(2)
        when 'lbs' then (value.to_f * 0.453592).round(2)
        when /\A(?:tonnes?|t)\z/ then (value.to_f * 1000).round(2)
        when /\A(?:gallons?|g)\z/ then (value.to_f * 3.78541).round(2)
        when /\A(?:liters?|litres?|l)\z/ then (value.to_f).round(2)
        when 'metres/feet' # invalid unit from http://www.nya.co.uk/boatsxml.php
        else
            log_warning 'Unknown unit', "#{unit}: #{value}"
            nil
        end
      end
    end
  end
end