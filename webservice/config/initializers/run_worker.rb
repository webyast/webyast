
def set
    ENV["RUN_WORKER"] = 'true'
    puts "SET #{ENV["RUN_WORKER"]}"
end
  
def run 
  if ENV["RUN_WORKER"] = 'true'
    require File.join(File.dirname(__FILE__) + "/../../lib/plugin.rb")
    
    
    @container = Hash.new
    plugins = CachePlugin.find(:all, @container)
    
    @container.each do |key, value|
      puts "KEY #{key} VALUE #{value}"
    end
    
    require File.dirname("#{RAILS_ROOT}") + '/plugins/users/app/jobs/user_job.rb'
    require File.dirname("#{RAILS_ROOT}") + '/plugins/status/app/jobs/status_job.rb'
    
    puts "START DELAYED JOB"
    Delayed::Job.enqueue(UsersJob.new, 3, 1.seconds.from_now)
#    Delayed::Job.enqueue(StatusJob.new, -3, 1.seconds.from_now)
  end
end

set()
run()



