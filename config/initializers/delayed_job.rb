Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 5
Delayed::Worker.max_attempts = 5 # period will be (retry ** 4)
Delayed::Worker.max_run_time = 48.hours
Delayed::Worker.read_ahead = 10
Delayed::Worker.default_priority = 0
Delayed::Worker.default_queue_name = 'default'
Delayed::Worker.delay_jobs = !Rails.env.test?
Delayed::Worker.raise_signal_exceptions = :term
Delayed::Worker.logger = Logger.new("#{Rails.root}/log/delayed_job.log", 5, 50.megabytes)

module Delayed
  module Plugins
    class ErrorsNotifier < Plugin

      callbacks do |lifecycle|
        lifecycle.around(:invoke_job) do |job, *args, &block|
          begin
            block.call(job, *args)
          rescue StandardError => error
            context = {job: {id: job.id, handler: job.handler}, error_location: 'Delayed Job Worker'}
            Rightboat::CleverErrorsNotifier.try_notify(error, nil, nil, context)
            raise error
          end
        end
      end

    end
  end
end

Delayed::Worker.plugins << Delayed::Plugins::ErrorsNotifier
