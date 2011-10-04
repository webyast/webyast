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

class FakeDbusGranted
  attr_reader :last_perms, :last_user
  def revoke(perms,user)
    @last_perms = perms
    @last_user = user
  end

  def grant(perms,user)
    revoke perms,user
  end

  def check(perms,user)
    raise "Polkit accept only string" unless perms.instance_of? Array
    if perms == ["test_polkit_override"] ||
       user == "network_admin" ||
       perms == ["test_polkit_override"]
      [["yes"]]
    else
      [["no"]]
    end
  end
end

class FakeDbusRevoked
  attr_reader :last_perms, :last_user
  def revoke(perms,user)
    @last_perms = perms
    @last_user = user
  end

  def grant(perms,user)
    revoke perms,user
  end

  def check(perms,user)
    [["no"]]
  end
end



class CurrentLogin
  attr_reader :login
  
  def initialize login
    @login = login
  end
end

unless defined? USER_ROLES_CONFIG
  USER_ROLES_CONFIG = File.join(File.dirname(__FILE__), "..", "fixtures", "yast_user_roles")
end


require File.join(File.dirname(__FILE__),"..", "test_helper")

class YastRolesTest < ActiveSupport::TestCase
  include YastRoles
  
  attr_reader :current_account
  
  def setup
    # FIXME: this needs proper PolKit mocking !
    @current_account = CurrentLogin.new "root" # be brave
  end
    
  def test_permission_check_trivial
    dbus_obj = FakeDbusRevoked.new
    Permission.stubs(:dbus_obj).returns(dbus_obj)
    assert_raise(NoPermissionException) { permission_check(nil) }
  end
  
  def test_permission_check_no_account
    @current_account = nil
    assert_raise(NotLoggedException) { permission_check(nil) }
  end
  
  def test_action_nil
    dbus_obj = FakeDbusRevoked.new
    Permission.stubs(:dbus_obj).returns(dbus_obj)
    assert_raise(NoPermissionException) { permission_check(nil) }
  end    
  
  def test_action_dummy
    dbus_obj = FakeDbusRevoked.new
    Permission.stubs(:dbus_obj).returns(dbus_obj)
    assert_raise(NoPermissionException) { permission_check("dummy") }
  end    

  def test_polkit_override
    dbus_obj = FakeDbusGranted.new
    Permission.stubs(:dbus_obj).returns(dbus_obj)
    assert permission_check("test_polkit_override")
  end

  def test_accept_string_polkit
    dbus_obj = FakeDbusGranted.new
    Permission.stubs(:dbus_obj).returns(dbus_obj)
    assert permission_check(:"test_polkit_override")
  end

  # test/fixtures/yast_user_roles assign "network_admin" role to user "root"
  def test_role_ok
    dbus_obj = FakeDbusGranted.new
    Permission.stubs(:dbus_obj).returns(dbus_obj)
#FIXME    assert permission_check("dummy")
  end
  
  def test_role_not_ok
    @current_account = CurrentLogin.new "nobody"
    dbus_obj = FakeDbusGranted.new
    Permission.stubs(:dbus_obj).returns(dbus_obj)
    assert_raise(NoPermissionException) { permission_check("dummy") }
  end
end
