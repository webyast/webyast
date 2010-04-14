# override path to the test sqlite3 database
# use value from TEST_DB_PATH environment variable
#
# needed during RPM build
#
# example: TEST_DB_PATH=/tmp/test_db.sqlite3 rake test
#


task :override_test_db do
  if !ENV['TEST_DB_PATH'].blank?
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

