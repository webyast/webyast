#--
# Webyast framework
#
# Copyright (C) 2009, 2010 Novell, Inc. 
#   This library is free software; you can redistribute it and/or modify
# it only under the terms of version 2.1 of the GNU Lesser General Public
# License as published by the Free Software Foundation. 
#
#   This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more 
# details. 
#
#   You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software 
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#++

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
