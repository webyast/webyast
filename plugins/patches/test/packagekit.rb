#
# Testing PackageKit via D-Bus
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
    
    # get transaction id via this interface
    tid = packagekit_iface.GetTid
    assert tid
    
    # retrieve transaction object
    transaction_proxy = pk_service.object(tid[0])
    assert transaction_proxy
    transaction_proxy.introspect
    
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