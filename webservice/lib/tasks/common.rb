# load common (rest-service, web-client) rake task
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/packagetask'

require File.join(File.dirname(__FILE__), '..', '..', 'config', 'boot')

begin
  # assume development environment
  commondir = File.expand_path(File.join('..','..','..', 'webservice-tasks', 'lib'), File.dirname(__FILE__))
  $:.unshift(commondir) if File.directory?( commondir )
  require 'tasks/webservice'
rescue LoadError => e
  $stderr.puts "Install rubygem-webyast-rake-tasks.rpm"
end

# load the shared rake files from the package itself
# skip 'deploy_local' task, it's redefined here
WebserviceTasks.loadTasks(:exclude => ["deploy_local.rake"])

# this call also loads WebserviceTasks but the second call is ignored there
# so this 'require' must be called _after_ WebserviceTasks.loadTasks
require 'tasks/rails'

require 'fileutils'

desc 'Default: run unit tests.'
task :default => :test
