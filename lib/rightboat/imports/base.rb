require 'mechanize'
require 'nokogiri'

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
        log_ex e, 'Unexpected error'
        raise e
      ensure
        @import_trail.touch(:finished_at)
      end

      def starting
        @import.param.each { |key, value| instance_variable_set("@#{key}", value) }

        @agent = Mechanize.new
        @agent.user_agent_alias = 'Mechanize'
        @agent.ssl_version = 'SSLv3'
        @agent.keep_alive = false
        @agent.max_history = 3
        @agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
        @agent.read_timeout = 120
        @agent.open_timeout = 120

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
              log_ex e, 'Thread error'
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

        if @missing_attrs.present?
          log "MISSING ATTRIBUTES: #{@missing_attrs.inspect}"
        end

        if @scraped_source_ids.none?
          log_error 'Import Blank'
          ImportMailer.import_blank(@import).deliver_now
          return
        end

        if @jobs_queue.empty? # all jobs processed
          remove_old_boats
        end

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
        @@import_types ||= Dir["#{Rails.root}/lib/rightboat/imports/sources/*"].map { |path| File.basename(path, '.*') }
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

      private

      def get(url, params = [], referer = nil, headers = {})
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
        ImportMailer.process_error(e, @import, job).deliver_now
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
          log_error source_boat.error_msg, 'Save Boat Error'
          increment_stats << ['not_saved_count', 1]
        end

        increment_stats << ['boats_count', 1]
        ImportTrail.where(id: @import_trail.id).update_all(increment_stats.map { |col, cnt| "#{col} = #{col} + #{cnt}" }.join(', '))
      rescue StandardError => e
        log_ex e, 'Save Error'
        ImportMailer.process_result_error(e, @import).deliver_now
      end

      def remove_old_boats
        delete_source_ids = (@old_source_ids - @scraped_source_ids).reject(&:blank?)
        delete_boats = @user.boats.where(source_id: delete_source_ids).to_a
        delete_boats.each do |boat|
          log "Deleting Boat id=#{boat.id} source_id=#{boat.source_id}"
          boat.destroy
        end

        @import_trail.update_attribute(:deleted_count, delete_boats.size)
      end

      def init_logger
        dir_path = Rails.root + "#{'../shared/' if !Rails.env.development?}log/imports/#{Time.current.strftime('%F')}"
        dir = FileUtils.mkdir_p(dir_path).first
        @log_path = "#{dir}/import-log-#{@import_trail.id}-#{@import.id}-#{@import.import_type}-#{Time.current.strftime('%H-%M-%S')}.log"
        @logger = Logger.new(@log_path)
      end

      def log(str)
        @logger.info str
        puts str if Rails.env.development?
      end

      def log_error(error_msg, short_msg = nil)
        log error_msg
        @import_trail.update_attribute(:error_msg, short_msg || error_msg)
      end

      def log_ex(e, short_msg)
        backtrace_lines_count = Rails.env.development? ? 50 : 8
        log_error "#{e.class.name} Error: #{e.message}\n#{e.backtrace.first(backtrace_lines_count).join("\n")}", short_msg
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