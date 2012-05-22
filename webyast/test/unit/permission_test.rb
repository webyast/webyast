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

require File.dirname(__FILE__) + '/../test_helper'

# Test Permission class

class PermissionTest < ActiveSupport::TestCase
  TEST_DATA_ACTIONS = [
    "org.opensuse.yast.modules.ysr.statelessregister",
    "org.opensuse.yast.modules.ysr.getregistrationconfig",
    "org.opensuse.yast.modules.ysr.setregistrationconfig",
    "org.freedesktop.network-manager-settings.system.modify",
    "org.opensuse.yast.module-manager.import",
    "org.opensuse.yast.module-manager.lock",
    "org.opensuse.yast.scr.read",
    "org.opensuse.yast.modules.yapi.users.usersget",
    "org.opensuse.yast.modules.yapi.users.userget",
    "org.opensuse.yast.modules.yapi.users.usermodify",
    "org.opensuse.yast.modules.yapi.users.useradd",
    "org.opensuse.yast.modules.yapi.users.userdelete",
    "org.opensuse.yast.permissions.read",
    "org.opensuse.yast.permissions.write"
  ]

  PATCHES_READ = [{:granted=>true, :id=>"org.opensuse.yast.modules.yapi.patches.read"}]

  def setup
    @user = "test"
    Permission.stubs(:all_actions).returns(TEST_DATA_ACTIONS)
    Permission.stubs(:find).with(:all, {:user_id => @user}).returns(TEST_DATA_ACTIONS)
    Permission.stubs(:find).with("org.opensuse.yast.modules.yapi.patches.read", {:user_id => @user}).returns(PATCHES_READ)
    Permission.stubs(:find).with(:all).returns(TEST_DATA_ACTIONS)
  end

  def test_find_all
    perm = Permission.find(:all)
    # FIXME: useless, Permission.find(:all) is stubbed, the test always passes
    assert_equal 14,perm.size #test all yast perm is loaded
  end


  def test_get_cache_timestamp
    timestamp = Permission.get_cache_timestamp
    assert_not_nil timestamp
    assert_kind_of(Integer, timestamp)
  end

  def test_cache_valid
    assert(Permission.get_cache_timestamp)
  end

  def test_set_permissions
    Permission.set_permissions(@user, ["org.opensuse.yast.modules.yapi.patches.read"])
    # FIXME: useless, Permission.find(:all, {:user_id => @user}) is stubbed, the test cannot succeed
    #user_permissions = Permission.find(:all,{:user_id => @user})
    #assert(user_permissions.include?("org.opensuse.yast.modules.yapi.patches.read"))
  end

  def test_find_for_user
    # FIXME: useless, Permission.find(:all, {:user_id => @user}) is stubbed, the test always passes
    perm = Permission.find(:all,{:user_id => @user})
    assert_equal 14,perm.size
  end

  def test_find_with_filter
    perm = Permission.find("org.opensuse.yast.modules.yapi.patches.read",{:user_id => @user})
    assert_equal 1,perm.size
  end

  def test_serialization
    perm = Permission.find(:all)
    assert_not_nil perm.to_xml
    assert_not_nil perm.to_json
    perm = Permission.find(:all,{:user_id => @user})
    assert_not_nil perm.to_xml
    assert_not_nil perm.to_json
  end

end
