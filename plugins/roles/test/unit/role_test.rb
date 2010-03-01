require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'mocha'
require 'role'

class RoleTest < ActiveSupport::TestCase
  def setup
    #set fixtures
    Role.const_set(:ROLES_DEF_PATH, File.join( File.dirname(__FILE__), "..","fixtures","roles.yml"))
    Role.const_set(:ROLES_ASSIGN_PATH, File.join( File.dirname(__FILE__), "..","fixtures","roles_assign.yml"))
  end

  def test_find_all
    roles = Role.find
    assert_equal 3,roles.size
    test_role = roles.find { |r| r.name.to_s == "test" }
    assert test_role
    assert_equal 3,test_role.users.size
    assert_equal 2,test_role.permissions.size
  end

  def test_find_id
    test_role = Role.find :test
    assert test_role
    assert_equal 3,test_role.users.size
    assert_equal 2,test_role.permissions.size
  end
end
