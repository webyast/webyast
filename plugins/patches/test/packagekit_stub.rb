#
# packagekit_stub.rb
#
# Stubs for PackageKit/D-Bus
#
#

require File.join(File.dirname(__FILE__), "test_helper")

class PackageKitStub

  SERVICE = "org.freedesktop.PackageKit"
  PATH = "/org/freedesktop/PackageKit"
  TRANSACTION = "#{SERVICE}.Transaction"
  TID = 42 # (dummy) transaction id

  def self.stub!

    #
    # PackageKit stubbing
    #
    # We mock all calls needed to access the PackageKit
    # dbus service
    #
    # Reference: http://www.packagekit.org/gtk-doc/index.html
    #
    
    #
    # PackageKit service
    #
    
    # create (dormant) pk_service
    pk_service = DBus::Service.new(SERVICE, DBus::SystemBus.instance)

    # stub:     pk_service = system_bus.service("org.freedesktop.PackageKit")    
    DBus::SystemBus.instance.stubs(:service).with(SERVICE).returns(pk_service)

    #
    # PackageKit proxy object
    #
    packagekit_proxy = DBus::ProxyObject.new(DBus::SystemBus.instance, SERVICE, PATH)

    # stub:     packagekit_proxy = pk_service.object("/org/freedesktop/PackageKit")
    pk_service.stubs(:object).with(PATH).returns(packagekit_proxy)

    # stub:     packagekit_proxy.introspect
    packagekit_proxy.stubs(:introspect).returns(true)
    packagekit_proxy.stubs(:has_iface?).returns(true)

    #
    # PackageKit interface
    #
    packagekit_iface = DBus::ProxyObjectInterface.new(packagekit_proxy, SERVICE)
    
    # stub:     packagekit_iface = packagekit_proxy["org.freedesktop.PackageKit"]
    packagekit_proxy[SERVICE] = packagekit_iface
    
    # stub:     tid = packagekit_iface.GetTid
    packagekit_iface.stubs(:GetTid).returns([TID])
        
    #
    # PackageKit transaction proxy
    #
    transaction_proxy = DBus::ProxyObject.new(DBus::SystemBus.instance, SERVICE, PATH)
    
    # stub:    transaction_proxy = pk_service.object(tid[0])
    pk_service.stubs(:object).with(TID).returns(transaction_proxy)

    # stub:    transaction_proxy.introspect
    transaction_proxy.stubs(:introspect).returns(true)
    transaction_proxy.stubs(:has_iface?).returns(true)

    #
    # PackageKit transaction interface
    #
    transaction_iface = DBus::ProxyObjectInterface.new(pk_service, TRANSACTION)
    
    # stub:    transaction_iface = transaction_proxy["org.freedesktop.PackageKit.Transaction"]
    transaction_proxy[TRANSACTION] = transaction_iface

    # stub:     packagekit_iface.SuggestDaemonQuit
    packagekit_iface.stubs(:SuggestDaemonQuit).returns(true)

    # stub:    transaction_iface.GetUpdates("NONE")
    transaction_iface.stubs(:GetUpdates).with("NONE").returns(true)
    
  end # stub !
  
end # PackageKitStub
