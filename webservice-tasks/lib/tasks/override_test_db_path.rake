#--
# Webyast Webservice framework
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

# override path to the test sqlite3 database
# use value from TEST_DB_PATH environment variable
#
# needed during RPM build
#
# example: TEST_DB_PATH=/tmp/test_db.sqlite3 rake test
#


task :override_test_db do
  unless ENV['TEST_DB_PATH'].nil? || ENV['TEST_DB_PATH'].empty?
    puts "Using DB file for tests: #{ENV['TEST_DB_PATH']}"

    # redefine the database config value in Rails::Configuration class
    module Rails
      class Configuration
        alias database_configuration_orig database_configuration

        def database_configuration
          ret = database_configuration_orig
          ret['test']['database'] = ENV['TEST_DB_PATH']
          return ret
        end
      end
    end

    # modify the current DB config if already loaded
    require 'active_record'
    if !ActiveRecord::Base.configurations.blank?
      ActiveRecord::Base.configurations['test']['database'] = ENV['TEST_DB_PATH']
    end
  end
end

# add a new dependency to the tasks which require 
# changed DB location

task :environment => :override_test_db

task :test => :override_test_db

namespace :db do
  task :load_config => :override_test_db
end

