
  class PluginJob < Struct.new(:function_string)
    def perform
      function_array = function_string.split(":")
      function_class = (function_array.first).classify
      object = Object.const_get(function_class) rescue $!
      if object.class != NameError && object.respond_to?(function_array[1])
        puts "xxxxxxxxxxxxx #{object.method(function_array[1]).call.inspect}"
      end
    end    
  end  


def set
    ENV["RUN_WORKER"] = 'true'
    puts "SET #{ENV["RUN_WORKER"]}"
end
  
def run 
  if ENV["RUN_WORKER"] = 'true'
    models = []
    resources = Resource.find :all
    resources.each  do |resource|
      name = resource.href.split("/").last
      status = Object.const_get((name).classify) rescue $!
      if status.class != NameError 
        if status.respond_to?(:find)
#          Delayed::Job.enqueue(PluginJob.new("#{name}:find:all"), -3, 5.seconds.from_now)
        end
        if status.respond_to?(:find_all) 
#          Delayed::Job.enqueue(PluginJob.new("#{name}:find_all"), -3, 5.seconds.from_now)
        end
      end
    end

    Delayed::Job.enqueue(PluginJob.new("users:find_all"), -3, 5.seconds.from_now)
  end
end

set()
run()



