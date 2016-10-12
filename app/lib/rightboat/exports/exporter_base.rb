module Rightboat
  module Exports
    class ExporterBase

      def initialize(export)
        @export = export
        @user = export.user
      end

      def run
        starting
        do_export
      rescue StandardError => e
        log_ex e, 'Unexpected Error'
        raise e
      ensure
        @file&.close

        ExpertMailer.exporting_errors(@export.id).deliver_now if @export.error_msg

        @export.touch(:finished_at)
        log "Finished in #{@export.duration.strftime('%H:%M:%S')}"
      end

      def starting
        @export.touch(:started_at)
        init_logger
        init_export_file
        log "Started export_file=#{@file.path}"
      end

      def init_logger
        FileUtils.mkdir_p("#{Rails.root}/#{@export.log_dir}")
        @logger = Logger.new(@export.log_path)
        @logger.level = 0 # log all
      end

      def init_export_file
        file_path = "#{Rails.root}/public#{@export.feed_public_path}"
        FileUtils.mkdir_p(File.dirname(file_path))
        @file = File.open(file_path, 'w+')
      end

      # override this
      def do_export
      end

      # log levels: :debug, :info, :warn, :error, :fatal
      def log(str, kind = :info)
        @logger.send kind, str
        puts str if Rails.env.development?
      end

      def log_error(short_msg, debug_info = nil)
        log "#{short_msg}. #{debug_info}", :error
        @export.update_column(:error_msg, short_msg) if !@export.error_msg
      end

      def log_warning(short_msg, debug_info = nil)
        log "#{short_msg}. #{debug_info}", :warn
      end

      def log_ex(e, short_msg)
        backtrace_lines_count = Rails.env.development? ? 50 : 20
        log_error short_msg, "#{e.class.name} Error: #{e.message}\n#{e.backtrace.first(backtrace_lines_count).join("\n")}"
      end

    end
  end
end
