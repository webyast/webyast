Delayed::Worker.destroy_failed_jobs = true
Delayed::Worker.sleep_delay = 1
Delayed::Worker.max_attempts = 3
Delayed::Worker.max_run_time = 5.minutes
Delayed::Worker.delay_jobs = !Rails.env.test?

ENV["RUN_WORKER"] = 'true'
