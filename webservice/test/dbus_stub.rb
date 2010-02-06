#
# dbus_stub.rb
#
# Stubs for D-Bus
#
#

require 'dbus'

class DBusStub

  attr_reader :bus, :service
  
  #
  # Initialize the service and stub bus.service
  #
  
  def initialize bus, service

    # Map pathes to stubbed proxies
    @proxies = {}
    
    @bus = case bus
                   when :system: DBus::SystemBus.instance
                   when :session: DBus::SessionBus.instance
		   else
		     raise "'bus' parameter must be :system or :session"
		   end
		   
    @service_name = service		   
    @service = DBus::Service.new(service, @bus)

    # stub:     service = system_bus.service("org.foo.bar")    
    @bus.stubs(:service).with(service).returns(@service)
  end
  
  #
  # get a proxy for a given object path
  # if service is given, also create the interface
  #
  def proxy path, service = nil
    proxy = @proxies[path]
    unless proxy
      proxy = DBus::ProxyObject.new(@bus, @service_name, path)
      
      proxy.stubs(:dbus_stub).returns(self)

      # stub:     @proxy = @service.object("/foo/bar/baz")
      @service.stubs(:object).with(path).returns(proxy)
      
      @proxies[path] = proxy
    end
    if service
      [proxy, self.interface(proxy,service)]
    else
      proxy
    end
  end
  
  #
  # Add an interface to an existing proxy
  #
  def interface proxy, service
    iface = proxy[service]
    unless iface
      # stub:     @proxy.introspect
      proxy.stubs(:introspect).returns(true)
      proxy.stubs(:has_iface?).with(service).returns(true)

      #
      # interface
      #
      iface = DBus::ProxyObjectInterface.new(proxy, service)
    
      # stub:     iface = @proxy["org.freedesktop.PackageKit"]
      proxy[service] = iface
    end
    iface
  end
  
end # DBusStub
