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

ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require File.join(File.dirname(__FILE__),"plugin_basic_tests")
require 'rails/test_help'

class ActionController::TestCase
  include Devise::TestHelpers
end

class ActiveSupport::TestCase
  def clean_backtrace(&block)
    yield
  rescue ActiveSupport::TestCase::Assertion => error
    framework_path = Regexp.new(File.expand_path("#{File.dirname(__FILE__)}/assertions"))
    error.backtrace.reject! { |line| File.expand_path(line) =~ framework_path }
    raise
  end

end

## use a different DB for tests -  needed during RPM build
#if !ENV['TEST_DB_PATH'].nil? && ENV['RAILS_ENV'] == 'test'
#  Rails.logger.debug "Using DB file for tests: #{ENV['TEST_DB_PATH']}"

#  # read the current config
#  dbconf = Rails::Configuration.new.database_configuration['test']

#  # update the config and make a new DB connection
#  require 'active_record'
#  dbconf['database'] = ENV['TEST_DB_PATH']
#  ActiveRecord::Base.establish_connection(dbconf)
#  ActiveRecord::Base.connection
#end
