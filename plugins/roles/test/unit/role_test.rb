#--
# Copyright (c) 2009-2010 Novell, Inc.
# 
# All Rights Reserved.
# 
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License
# as published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
# 
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#++

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class RoleTest < ActiveSupport::TestCase
  def setup
    #set fixtures, renew test files
		@test_path = File.join( Dir.tmpdir(), "webyast-roles-testsuite-tmpdir")
    `mkdir -p #{@test_path}`
		`cp #{File.join(File.dirname(__FILE__),'..','fixtures')}/* #{@test_path}`
    Role.const_set(:ROLES_DEF_PATH, File.join( @test_path, "roles.yml"))
    Role.const_set(:ROLES_ASSIGN_PATH, File.join( @test_path, "roles_assign.yml"))
  end

  def teardown
    `rm -rf #{@test_path}`
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
