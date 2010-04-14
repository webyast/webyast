# use a different DB for tests,
# needed during RPM build

if !ENV['TEST_DB_PATH'].nil? && ENV['RAILS_ENV'] == 'test'
  Rails.logger.debug "Using DB file for tests: #{ENV['TEST_DB_PATH']}"

  # read the current config
  dbconf = Rails::Configuration.new.database_configuration['test']

  # update the config and make a new DB connection
  require 'active_record'
  dbconf['database'] = ENV['TEST_DB_PATH']
  ActiveRecord::Base.establish_connection(dbconf)
  ActiveRecord::Base.connection
end

