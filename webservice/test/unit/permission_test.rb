#--
# Webyast Webservice framework
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
require 'polkit'

# Test Permission class

class PermissionTest < ActiveSupport::TestCase
TEST_DATA_ACTIONS = <<EOF
org.opensuse.yast.modules.ysr.statelessregister
org.opensuse.yast.modules.ysr.getregistrationconfig
org.opensuse.yast.modules.ysr.setregistrationconfig
org.freedesktop.network-manager-settings.system.modify
org.opensuse.yast.module-manager.import
org.opensuse.yast.module-manager.lock
org.opensuse.yast.scr.read
org.opensuse.yast.modules.yapi.users.usersget
org.opensuse.yast.modules.yapi.users.userget
org.opensuse.yast.modules.yapi.users.usermodify
org.opensuse.yast.modules.yapi.users.useradd
org.opensuse.yast.modules.yapi.users.userdelete
org.opensuse.yast.permissions.read
org.opensuse.yast.permissions.write
EOF

TEST_DATA_GRANT = [
"org.opensuse.yast.modules.ysr.statelessregister",
"org.opensuse.yast.modules.ysr.getregistrationconfig",
"org.freedesktop.network-manager-settings.system.modify",
"org.opensuse.yast.module-manager.import"]


  def setup
    Permission.any_instance.stubs(:all_actions).returns(TEST_DATA_ACTIONS)
    PolKit.stubs(:polkit_check).with(){ |p,u| TEST_DATA_GRANT.include? p.to_s}.returns(:yes)
    PolKit.stubs(:polkit_check).with(){ |p,u| !TEST_DATA_GRANT.include?(p.to_s)}.returns(:no)
  end

  def test_find_all
    perm = Permission.find(:all)
#test all yast perm is loaded
    assert_equal 10,perm.permissions.size
#test that all have not granted
    perm.permissions.each do |p|
      assert !p[:granted]
      assert !p[:id].blank?
    end
  end

  def test_find_for_user
    perm = Permission.find(:all,{:user_id => "test"})
#test all loaded
    assert_equal 10,perm.permissions.size
#check if is granted
    perm.permissions.each do |p|
      if p[:id]=="org.opensuse.yast.modules.ysr.statelessregister"
        assert p[:granted] 
      end
      assert !p[:granted] if p[:id]=="org.opensuse.yast.modules.ysr.setregisterconfig"
    end
  end

  def test_find_with_filter
    perm = Permission.find(:all,{:user_id => "test",:filter => "org.opensuse.yast.permissions.write"})

#test all loaded
    assert_equal 1,perm.permissions.size
#check if is granted
    perm.permissions.each do |p|
      assert p[:id] == "org.opensuse.yast.permissions.write"
    end
  end

  def test_serialization
    perm = Permission.find(:all)
    assert_not_nil perm.to_xml
    assert_not_nil perm.to_json
    perm = Permission.find(:all,{:user_id => "test"})
    assert_not_nil perm.to_xml
    assert_not_nil perm.to_json
  end

GENERIC_EXCEPTION_MESSAGE = "Polkit not run"
  def test_exception_handling
    PolKit.stubs(:polkit_check).raises(RuntimeError.new("PolicyKit exception: test does not exist"))
    assert_raise (InvalidParameters.new( :user_id => "UNKNOWN")) do
      perm = Permission.find(:all,{:user_id => "test",:filter => "org.opensuse.yast.permissions.write"})
    end

    PolKit.stubs(:polkit_check).raises(RuntimeError.new(GENERIC_EXCEPTION_MESSAGE))
    assert_raise (PolicyKitException.new(GENERIC_EXCEPTION_MESSAGE,"test","org.opensuse.yast.permissions.write")) do
      perm = Permission.find(:all,{:user_id => "test",:filter => "org.opensuse.yast.permissions.write"})
    end
  end
end
