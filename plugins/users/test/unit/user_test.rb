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
require 'test/unit'
require "yast_service"
#require 'mocha'
#require 'pp'

class UserTest < Test::Unit::TestCase

  def setup

    parameters = {'user_attributes' => ['as', ['cn', 'uidNumber', 'homeDirectory',
          'grouplist', 'uid', 'loginShell', 'groupname']], 'type' => 'local', 'index' => ['s', 'uid']}
    result = {"testuser1"=>{"cn"=>"testuser1", "groupname"=>"users", "uidNumber"=>1000, "homeDirectory"=>"/home/testuser1"},
										"testuser2"=>{"cn"=>"testuser2", "groupname"=>"users", "uidNumber"=>1010, "homeDirectory"=>"/home/testuser1"}}

    YastService.stubs(:Call).with("YaPI::USERS::UsersGet", parameters).returns(result)

    short_parameters	= {'user_attributes' => ['as', ['uid', 'cn']],
      'type' => 'local', 'index' => ['s', 'uid']}
    short_result = {
	"testuser1"=>{"cn"=>"testuser1", "uid" => "testuser1"},
	"testuser2"=>{"cn"=>"Test user2", "uid" => "testuser2"}}
    YastService.stubs(:Call).with("YaPI::USERS::UsersGet", short_parameters).returns(short_result)
  end

  def test_user
    users = User.find_all
    assert_equal(2, users.size)
  end

  def test_user_uid
    users = User.find_all ({ "attributes" => "uid,cn"})
    assert_equal(2, users.size)
    assert users[0].uid_number == ""
    assert users[0].uid == "testuser1"
  end
  
end
