require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'mocha'
require 'role'

class RoleTest < ActiveSupport::TestCase
  def setup
    #set fixtures, renew test files
		test_path = File.join( File.dirname(__FILE__), "..")
		`cp #{test_path}/fixtures/* #{test_path}/tmp/`
    Role.const_set(:ROLES_DEF_PATH, File.join( File.dirname(__FILE__), "..","tmp","roles.yml"))
    Role.const_set(:ROLES_ASSIGN_PATH, File.join( File.dirname(__FILE__), "..","tmp","roles_assign.yml"))
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

TEST_DATA = { :name => "create_test", :permissions => ["org.opensuse.test.lest"],
							:users => ["tux"] }
	def test_create_role
		Role.new.load(TEST_DATA).save
    roles = Role.find
    assert_equal 4,roles.size
    test_role = roles.find { |r| r.name.to_s == TEST_DATA[:name] }
    assert test_role
    assert_equal TEST_DATA[:users],test_role.users
    assert_equal TEST_DATA[:permissions],test_role.permissions
	end

	def test_update_role
		r = Role.find(:test)
		r.users = TEST_DATA[:users]
		r.permissions = TEST_DATA[:permissions]
		r.save
    roles = Role.find
    assert_equal 3,roles.size
    test_role = roles.find { |r| r.name.to_sym == :test }
    assert test_role
    assert_equal TEST_DATA[:users],test_role.users
    assert_equal TEST_DATA[:permissions],test_role.permissions
	end

	def test_update_role
		Role.delete(:test)
    roles = Role.find
    assert_equal 2,roles.size
	end

end
