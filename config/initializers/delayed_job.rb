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

require 'sunspot/queue/delayed_job'
class Sunspot::Queue::DelayedJob::IndexJob; include Rightboat::DelayedJobNotifyOnError end
class Sunspot::Queue::DelayedJob::RemovalJob; include Rightboat::DelayedJobNotifyOnError end
