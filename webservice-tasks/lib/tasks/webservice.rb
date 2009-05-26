require 'rake'

# load all webservice *.rake files
Dir["#{File.dirname(__FILE__)}/*.rake"].each { |ext| load ext }
