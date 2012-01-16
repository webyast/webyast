# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Webyast::Application.initialize!

GettextI18nRails.translations_are_html_safe = true

STDERR.puts "********* Running in production mode" if Rails.env.production?
STDERR.puts "********* Running in development mode" if Rails.env.development?
STDERR.puts "********* Running in test mode" if Rails.env.test?

unless Rails.env.test?
#  delay_job_mutex.lock
#  if ENV["RUN_WORKER"] && YastCache.active
#    Thread::new do 
#      ENV["RUN_WORKER"] = 'false'
#      delay_job_mutex.lock #do not start before all jobs have been inserted
#      Delayed::Worker.new.start 
#    end
#  end
end

