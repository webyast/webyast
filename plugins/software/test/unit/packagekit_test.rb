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

#
# packagekit_test.rb
#
# Test 'PackageKit' class
#
#

require File.join(File.dirname(__FILE__), "..", "test_helper")
require File.join(File.dirname(__FILE__), "..", "packagekit_stub")

class PackageKitTest < ActiveSupport::TestCase
  require 'packagekit'

  def setup
    @pk_stub = PackageKitStub.new
    @transaction, @packagekit = PackageKit.connect
    
    rset = PackageKitResultSet.new "Package", :info => :s, :id => :s, :summary => :s
    rset << ["info1", "id1", "summary1"]
    rset << [:info2, :id2, :summary2]
    
    @pk_stub.result = rset
  end

  def test_connect
    assert @pk_stub
    assert @transaction
    assert @packagekit
  end
  
  def test_transact
    @transaction.stubs(:GetUpdates).with("NONE").returns(true)
    
    result = PackageKit.transact "GetUpdates", "NONE"
    assert result
  end
  
  def test_install
    @transaction.stubs(:UpdatePackages).returns(true)

    result = Patch.install :id1
    assert result
  end

  def test_zypp_error
    msg = DBus::Message.new
    msg.error_name = "org.freedesktop.DBus.Error.Spawn.ChildExited"
    @transaction.stubs(:GetUpdates).with("NONE").raises(DBus::Error.new(msg))
    File.stubs(:read).with("/var/run/zypp.pid").returns "42\n"

    assert_raises PackageKitError do
      result = PackageKit.transact "GetUpdates", "NONE"
    end
  end
  
  def test_packagekit_missing_error
    msg = DBus::Message.new
    msg.error_name = "org.freedesktop.DBus.Error.ServiceUnknown"
    msg.add_param(DBus::Type::STRING, "WTF PackageKit?!")
    @transaction.stubs(:GetUpdates).with("NONE").raises(DBus::Error.new(msg))

    assert_raises ServiceNotAvailable do
      result = PackageKit.transact "GetUpdates", "NONE"
    end
  end
  
end
