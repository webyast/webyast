require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'systemtime'
require 'mocha'

class RoleTest < ActiveSupport::TestCase
  def setup
    #set fixtures
    Role.ROLES_DEF_PATH = File.join ( File.dirname(__FILE__), "..","fixtures","roles.yml")
  end
end
