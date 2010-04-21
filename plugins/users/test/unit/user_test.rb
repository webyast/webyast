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
require 'mocha'
require 'pp'

class UserTest < Test::Unit::TestCase

  def setup

    parameters	= { "index" => ["s", "uid"], "user_attributes" =>  
        [ "as", [ "cn", "uidNumber", "homeDirectory",
                  "grouplist", "uid", "loginShell", "groupname" ] ]
    }
    YastService.stubs(:Call).with("YaPI::USERS::UsersGet", parameters).returns({"testuser1"=>{"cn"=>"testuser1", "groupname"=>"users", "uidNumber"=>1000, "homeDirectory"=>"/home/testuser1"},
										"testuser2"=>{"cn"=>"testuser2", "groupname"=>"users", "uidNumber"=>1010, "homeDirectory"=>"/home/testuser1"}})    
  end

  def test_user
    users = User.find_all
    assert_equal(2, users.size)
  end
  
end
