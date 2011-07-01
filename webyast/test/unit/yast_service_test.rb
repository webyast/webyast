#--
# Webyast framework
#
# Tests for lib/yast_service.rb
#
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

require File.join(File.dirname(__FILE__),"..", "test_helper")
require File.join(File.dirname(__FILE__),"..", "dbus_stub")

require 'yast_service'
require 'etc'

SERVICE = "org.opensuse.YaST.modules"
IMPORT_PATH = "/org/opensuse/YaST/modules"
IMPORT_IFACE = "org.opensuse.YaST.modules.ModuleManager"

YASTMETHOD = :Testing
YASTSERVICE = "Yast::Service"

PATH = "/org/opensuse/YaST/modules/" + YASTSERVICE.gsub("::", "/")
IFACE = "org.opensuse.YaST.Values"

class YastServiceTest < ActiveSupport::TestCase
# TODO FIXME: the test has been temporarily disabled because
# it gets stuck in OBS YaST:Web in openSUSE_FACTORY/i586 repo build (only!)
#
# See bug report: https://bugzilla.novell.com/show_bug.cgi?id=661473
#
#  def setup
#    DBus::SystemBus.stubs(:instance).returns(DBus::SessionBus.instance)
#    @y_stub = DBusStub.new :system, SERVICE
#    @y_service = @y_stub.service
#
#    @import_proxy, @import_iface = @y_stub.proxy IMPORT_PATH, IMPORT_IFACE
#
#    @import_iface.stubs(:Import).returns(true)
#
#    @yast_proxy, @yast_iface = @y_stub.proxy PATH, IFACE
#  end
#
#  test "report actual login" do
#    msg = DBus::Message.new(DBus::Message::ERROR)
#    msg.error_name = "org.freedesktop.PolicyKit.Error.NotAuthorized"
#    msg.add_param Integer, 42
#    dbe = DBus::Error.new(msg)
#    @yast_iface.stubs(YASTMETHOD).raises(dbe)
#
#    # bnc#601939
#    e = assert_raise NoPermissionException do
#      YastService.Call(YASTSERVICE + "::#{YASTMETHOD}")
#    end
#    assert_equal Etc.getlogin, e.user
#  end
end
