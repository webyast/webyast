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
# Testing PackageKit access via D-Bus
#
# *** This test requires a 'live' system with D-Bus running ***
#
require "dbus"

require File.join(File.dirname(__FILE__), "test_helper")

class ResolvableTest < ActiveSupport::TestCase

  SERVICE = "org.freedesktop.PackageKit"
  PATH = "/org/freedesktop/PackageKit"
  TRANSACTION = "#{SERVICE}.Transaction"
  TID = 100 # transaction id

  def test_packagekit
    system_bus = DBus::SystemBus.instance
    assert system_bus
    
    # connect to PackageKit service via SystemBus
    pk_service = system_bus.service SERVICE
    assert pk_service
    
    # Create PackageKit proxy object
    packagekit_proxy = pk_service.object PATH
    assert packagekit_proxy
    
    # learn about object
    packagekit_proxy.introspect

    # use the (generic) 'PackageKit' interface
    packagekit_iface = packagekit_proxy[SERVICE]
    assert packagekit_iface

    # Print object interfaces  
    packagekit_proxy.interfaces.each do |interface|  
      puts "PackageKit Proxy #{packagekit_proxy.path} provides Interface '#{interface}' with these methods:"  
      packagekit_proxy[interface].methods.each do |key,value|  
	rets = value.rets.blank? ? "void" : value.rets
	puts "\t#{rets} #{key}( #{value.params} )"  
      end  
    end  

    # get transaction id via this interface
    tid = packagekit_iface.GetTid
    assert tid
    
    # retrieve transaction object
    transaction_proxy = pk_service.object(tid[0])
    assert transaction_proxy
    transaction_proxy.introspect
    
    # Print object interfaces  
    transaction_proxy.interfaces.each do |interface|  
      puts "Transaction Proxy #{transaction_proxy.path} provides Interface '#{interface}' with these methods"  
      transaction_proxy[interface].methods.each do |key,value|  
	rets = value.rets.blank? ? "void" : value.rets
	puts "\t#{rets} #{key}( #{value.params} )"
      end  
    end  
    
    # use the 'Transaction' interface
    transaction_iface = transaction_proxy[TRANSACTION]
    assert transaction_iface
    transaction_proxy.default_iface = TRANSACTION

    dbusloop = DBus::Main.new
    assert dbusloop
    puts "Found PackageKit via D-Bus"

    dbusloop << DBus::SystemBus.instance
    transaction_proxy.on_signal("Error") do |u1,u2|
      puts "Error"
      dbusloop.quit
    end
    transaction_proxy.on_signal("Finished") do |u1,u2|
      puts "Finished"
      dbusloop.quit
    end
    transaction_proxy.on_signal("Package") do |line1,line2,line3|
      puts "Line1: #{line1}"
      puts "Line2: #{line2}"
      puts "Line3: #{line3}"
    end
    
    puts "-- Looking for yast packages --"
    transaction_iface.SearchName "installed;~devel", "yast2"

    puts "-- dbusloop run --"
    dbusloop.run
    puts "-- dbusloop quit --"

    packagekit_iface.SuggestDaemonQuit
  end
end
