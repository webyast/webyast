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

#
# dbus_stub.rb
#
# Stubs for D-Bus
#
# See http://en.opensuse.org/YaST/Web/Development/Testing/D-Bus
#
#
# Example usage:
#
#   # create the stub
#   dbus = DBusStub.new :system, "dbus.service.spec"
#
#   # create a service proxy
#   proxy = dbus.proxy "/path/to/service"
#
#   # add an interface to this proxy
#   interface = dbus.interface proxy, "dbus.service.spec.iface"
#
#   # the proxy and interface generation can be combined as
#
#   proxy,interface = dbus.proxy "/path/to/service", "dbus.service.spec.iface"
#
require 'dbus'

class DBusStub

  attr_reader :bus, :service
  
  #
  # Initialize the service and stub bus.service
  #
  #  bus: symbol identifying the bus, either ':system' or ':session'
  #  service: string identifying the service, something like "org.freedesktop.PackageKit"
  #
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
  #
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
