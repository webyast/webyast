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
require 'mocha'
#require File.expand_path( File.join("test","plugin_basic_tests"), RailsParent.parent )

class GroupsControllerTest < ActionController::TestCase
  fixtures :accounts

  GROUP_READ_DATA = { 'more_users' => { 'games' => 1,
                                        'tux' => 1
                                      },
                      'userlist' => {},
                      'gidNumber' => 100,
                      'cn' => 'users',
                      'userPassword' => 'x',
                      'type' => 'local'
                    }

  GROUP_LOCAL_CONFIG = { "type" => ["s","local"], "cn" => ["s","users"] }

  CREATE_LOCAL_CONFIG = { "type" => ["s","local"]}
``
  GROUP_SYSTEM_CONFIG = { "type" => ["s","system"], "cn" => ["s","users"] }

  UPDATE_PARAM_DATA = { "old_cn" => "users",
                       "gid" => 100,
                       "members" => [],
                       "cn" => "users2",
                       "group_type" => "local"
                     }

  CREATE_PARAM_DATA = { "old_cn" => "users",
                       "gid" => 100,
                       "members" => [],
                       "cn" => "users",
                       "group_type" => "local"
                     }

  CREATE_DATA = { "groups" => CREATE_PARAM_DATA }

  UPDATE_DATA = { "id" => "users", "groups" => UPDATE_PARAM_DATA }

  CREATE_WRITE_DATA= { 'userlist' => ["as", [] ],
                       'cn' => ["s",'users']
                     }

  UPDATE_WRITE_DATA= { 'userlist' => ["as", [] ],
                      'gidNumber' => ["i", 100],
                      'cn' => ["s",'users2']
                    }

  OK_RESULT = ""

  def setup
    @model_class = Group
    group_mock = Group.new(GROUP_READ_DATA)
    Group.stubs(:find).returns(group_mock)

    @controller = GroupsController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
    @data = UPDATE_DATA
  end

#  include PluginBasicTests

  def test_update
    mock_update
    put :update, UPDATE_DATA
    assert_response :success
  end

  def test_create
    mock_create
    put :create, CREATE_DATA
    assert_response :success
  end

  def mock_get
    YastService.stubs(:Call).with("YaPI::USERS::GroupGet",GROUP_LOCAL_CONFIG).once.returns(GROUP_READ_DATA)
  end

  def mock_update
    YastService.stubs(:Call).with("YaPI::USERS::GroupGet",GROUP_LOCAL_CONFIG).once.returns(GROUP_READ_DATA)
    YastService.stubs(:Call).with( "YaPI::USERS::GroupModify", GROUP_LOCAL_CONFIG, UPDATE_WRITE_DATA).once.returns(OK_RESULT)
    Group.stubs(:permission_check)
  end

  def mock_create
    YastService.stubs(:Call).with("YaPI::USERS::GroupGet",GROUP_LOCAL_CONFIG).once.returns({})
    YastService.stubs(:Call).with( "YaPI::USERS::GroupAdd", CREATE_LOCAL_CONFIG, CREATE_WRITE_DATA).once.returns(OK_RESULT)
    Group.stubs(:permission_check)
  end
end

