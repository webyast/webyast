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

require 'exceptions'

class YastService
  require "dbus"

  # cache the importer object, avoid recreation in every Import call
  @@importer = nil

  # avoid race conditions while accessing YaST
  #
  @@yast_mutex = Mutex.new

  # cache for imported namespaces, avoid importing an Yast name space
  # and introspecting the DBus object in every call
  # key: name space name, value: DBus object
  @@imported = {}

  #
  # YastService.lock
  #
  # Lock YastService for single use
  #
  def YastService.lock
    #      Rails.logger.info "DBUS locking"
    @@yast_mutex.lock
    #      Rails.logger.info "DBUS locked"
  end

  #
  # YastService.unlock
  #
  # Unlock YastService
  #
  def YastService.unlock
    if @@yast_mutex.locked?
      begin
        @@yast_mutex.unlock
      rescue Exception => e
        Rails.logger.debug "DBUS is not locked"
      end
      #        Rails.logger.info "DBUS unlocked"
    end
  end

  # call a Yast function using DBus service
  def YastService.Call(function, *arguments)

    YastService.lock #locking for other thread

    # connect to the system bus
    system_bus = DBus::SystemBus.instance # RORSCAN_ITL

    # get the Yast namespace service
    yast = system_bus.service('org.opensuse.YaST.modules') # RORSCAN_ITL

    # parse the function name
    parts = function.split('::')

    # get the last item (the function name)
    fce = parts.pop
    # format the namespace object name
    object = parts.join('/')
    namespace = parts.join('::')

    # has been the namespace already imported?
    if @@imported.has_key?(namespace)
	    dbusobj = @@imported[namespace]
    else
	    # lazy initialization of the importer object
	    if @@importer.nil?
        @@importer = yast.object('/org/opensuse/YaST/modules')
        @@importer.introspect
        @@importer.default_iface = 'org.opensuse.YaST.modules.ModuleManager'
	    end

	    # import the module
	    imported = @@importer.Import(namespace)

	    if imported
        dbusobj = yast.object('/org/opensuse/YaST/modules/' + object)
        dbusobj.introspect
        dbusobj.default_iface = 'org.opensuse.YaST.Values'

        @@imported[namespace] = dbusobj
      end
    end
    return dbusobj.send(fce, *arguments)[0]


    # handle DBus and PolicyKit errors
  rescue DBus::Error => dbe

    # handle org.freedesktop.PolicyKit.Error.NotAuthorized DBus Error
    if dbe.dbus_message.error_name == 'org.freedesktop.PolicyKit.Error.NotAuthorized' && dbe.dbus_message.params.size == 1
	    parms = dbe.dbus_message.params[0].split(' ')
	    
	    # Etc helps to retrieve the login of the REST service
	    require 'etc'
      # throw a PolicyKit exception instead of the DBus exception
      raise CanCan::AccessDenied.new(_("Not authorized! (%s)") % parms[0])
    end

    # rethrow other DBus Errors
    raise dbe

    # handle generic errors (e.g. non existing yast function)
  rescue Exception => e

    # rethow generic exceptions
    raise e
  ensure
    YastService.unlock #unlocking for other thread
  end
end

