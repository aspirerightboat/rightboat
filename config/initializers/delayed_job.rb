Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 5
Delayed::Worker.max_attempts = 5 # period will be (retry ** 4)
Delayed::Worker.max_run_time = 48.hours
Delayed::Worker.read_ahead = 10
Delayed::Worker.default_priority = 0
Delayed::Worker.default_queue_name = 'default'
Delayed::Worker.delay_jobs = !Rails.env.test?
Delayed::Worker.raise_signal_exceptions = :term
Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'delayed_job.log'),
                                    5, # 5 files total
                                    50*1024*1024) # 50 megabytes each
