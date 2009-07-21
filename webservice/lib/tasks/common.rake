begin
      require 'tasks/webservice'
rescue LoadError => e
      $stderr.puts "Install rubygem-yast2-webservice-tasks.rpm"
end
