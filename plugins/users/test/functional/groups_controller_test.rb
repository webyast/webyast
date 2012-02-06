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
require File.join(RailsParent.parent, "test","devise_helper")

class GroupsControllerTest < ActionController::TestCase

  GROUP_READ_DATA = { 'more_users' => { 'games' => 1,
                                        'tux' => 1
                                      },
                      'userlist' => {},
                      'gidNumber' => 100,
                      'cn' => 'users',
                      'old_cn' => 'users',
                      'group_type' => 'local',
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
                       "members_string" => "",
                       "cn" => "users2",
                       "group_type" => "local"
                     }

  CREATE_PARAM_DATA = { "old_cn" => "users",
                       "gid" => 100,
                       "members" => [],
                       "members_string" => "",
                       "cn" => "users",
                       "group_type" => "local"
                     }

  CREATE_DATA = { "group" => CREATE_PARAM_DATA }

  UPDATE_DATA = { "id" => "users", "group" => UPDATE_PARAM_DATA }

  CREATE_WRITE_DATA= { 'userlist' => ["as", [] ],
                       'cn' => ["s",'users']
                     }

  UPDATE_WRITE_DATA= { 'userlist' => ["as", [] ],
                      'gidNumber' => ["i", 100],
                      'cn' => ["s",'users2']
                    }

  OK_RESULT = ""

  def setup
    devise_sign_in

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
    assert_response :redirect
  end

  def test_create
    mock_create
    put :create, CREATE_DATA
    assert_response :redirect
  end

  def test_delete_group
    mock_get
    mock_delete
    post :destroy, {:id => "users"}
    assert_response :redirect
    assert_valid_markup
    assert_redirected_to :action => :index
    assert_valid_markup
    assert_false flash.empty?
  end

  def test_rename_group
    post :update, {"group" => {"cn"=>"new_name", "old_cn" => "users"} }
    assert_response :redirect
    assert_valid_markup
    assert_redirected_to :action => :index
    assert_valid_markup
    assert_false flash.empty?
  end

  def test_groups_index_no_permissions
    GroupsController.any_instance.stubs(:yapi_perm_check).with("users.groupsget").raises(NoPermissionException.new("users.groupsget", "test"));
    GroupsController.any_instance.stubs(:yapi_perm_check).with("users.groupget").raises(NoPermissionException.new("users.groupget", "test"));
    get :index
    assert_response :redirect
    assert_false flash.empty?
    assert_valid_markup
  end

  def mock_get
    YastService.stubs(:Call).with("YaPI::USERS::GroupGet",GROUP_LOCAL_CONFIG).once.returns(GROUP_READ_DATA)
  end

  def mock_delete
    YastService.stubs(:Call).with('YaPI::USERS::GroupDelete', {'cn' => ['s', 'users'], 'type' => ['s', 'local']}).once.returns("")
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
