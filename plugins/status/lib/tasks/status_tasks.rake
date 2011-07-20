begin
  require 'tasks/webyast'
rescue LoadError => e
  $stderr.puts "Install rubygem-webyast-tasks.rpm"
end

