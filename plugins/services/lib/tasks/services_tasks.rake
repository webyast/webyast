begin
  require 'tasks/webyast'
rescue LoadError => e
  $stderr.puts "Install rubygem-yast2-webyast-tasks.rpm"
end

