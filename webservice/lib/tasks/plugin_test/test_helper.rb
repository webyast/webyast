rails_parent = ENV["RAILS_PARENT"]
unless rails_parent
  if File.directory?("../../webservice/")
     $stderr.puts "Taking ../../webservice/ for RAILS_PARENT"  
     rails_parent="../../webservice/"
  else
     $stderr.puts "Please set RAILS_PARENT environment"
     exit
  end
end
require File.expand_path(rails_parent + "/test/test_helper")
