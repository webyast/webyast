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
#dbus stubbing
require File.expand_path( File.join("test","dbus_stub"), RailsParent.parent )


class NtpTest < ActiveSupport::TestCase

  def setup
    dbus = DBusStub.new :system, "example.Service"
    proxy,@interface = dbus.proxy "/org/example/service/Interface", "example.service.Interface"
  end
  
  TEST_STRING = "Test string"
  def test_find
    @interface.stubs(:read).returns(TEST_STRING).once
    @interface.stubs(:write).never
    e = Example.find
    assert e
    assert_equal TEST_STRING, e.content
  end
  
  def test_update
    @interface.stubs(:write).once
    @interface.stubs(:read).never
    e = Example.new :content => TEST_STRING
    e.save
  end
end
