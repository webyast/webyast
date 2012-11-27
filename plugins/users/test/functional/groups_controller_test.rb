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
    @controller = GroupsController.new
    @model_class = Group
    group_mock = Group.new(GROUP_READ_DATA)
    Group.stubs(:find).returns(group_mock)
    @data = UPDATE_DATA

    @dbus_obj = FakeDbus.new
    Permission.stubs(:dbus_obj).returns(@dbus_obj)
  end

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
    assert_redirected_to :action => :index
    assert !flash.empty?
  end

  def test_rename_group
    YastService.stubs(:Call).with("YaPI::USERS::GroupGet",GROUP_LOCAL_CONFIG).once.returns(GROUP_READ_DATA)
    YastService.stubs(:Call).with( "YaPI::USERS::GroupModify", GROUP_LOCAL_CONFIG,  {'cn' => ['s', 'new_name'], 'gidNumber' => ['i', 0], 'userlist' => ['as', []]}).once.returns(OK_RESULT)
    post :update, {"group" => {"cn"=>"new_name", "old_cn" => "users", "group_type" => "local"} }

    assert_redirected_to :action => :index
    assert !flash.empty?
  end

  def test_groups_index_no_permissions
    GroupsController.any_instance.stubs(:authorize!).raises(CanCan::AccessDenied.new());
    get :index
    assert !flash.empty?
    assert_response  302 # Redirect
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
  end

  def mock_create
    YastService.stubs(:Call).with("YaPI::USERS::GroupGet",GROUP_LOCAL_CONFIG).once.returns({})
    YastService.stubs(:Call).with( "YaPI::USERS::GroupAdd", CREATE_LOCAL_CONFIG, CREATE_WRITE_DATA).once.returns(OK_RESULT)
  end
end
