#!/usr/bin/env ruby
#--
# Webyast Webservice framework
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


require 'rubygems'
require 'dbus'
require 'etc'
require 'polkit'

# Choose the bus (could also be DBus::session_bus, which is not suitable for a system service)
bus = DBus::system_bus
# Define the service name
service = bus.request_service("webyast.permissions.service")

class WebyastPermissionsService < DBus::Object

  # overriding DBus::Object#dispatch
  # It is needed because dispatch sent just parameters and without sender it is
  # imposible to check permissions of sender. So to avoid it add as last
  # parameter sender id.
  def dispatch(msg)
    msg.params << msg.sender
    super(msg)
  end

  def log(msg)
    f = File.new("/srv/www/yastws/log/permission_service.log","a",0600)
    f.write(msg+"\n")
    f.close
  end

  # Create an interface.
  dbus_interface "webyast.permissions.Interface" do
    dbus_method :grant, "out result:as, in permissions:as, in user:s" do |permissions,user,sender|
      result = execute("grant", permissions, user,sender)
      log "Grant permissions #{permissions.inspect} for user #{user} with result #{result.inspect}"
      [result]
    end
    dbus_method :revoke, "out result:as, in permissions:as, in user:s" do |permissions,user,sender|
      result = execute("revoke", permissions, user,sender)
      log "Revoke permissions #{permissions.inspect} for user #{user} with result #{result.inspect}"
      [result]
    end
  end

USER_REGEX=/^[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_][ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.-]*[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.$-]?$/
  def execute (command, permissions, user, sender)
    #TODO polkit check, user escaping, perm whitespacing
    return ["NOPERM"] unless check_polkit sender
    return ["USER_INVALID"] if user.match(USER_REGEX).nil?
    result = []
    permissions.each do |p|
      #whitespace check for valid permission string to avoid attack
      result << "perm #{p} is INVALID" if p.match(/^[a-zA-Z0-9.-]+$/).nil?
      result << `polkit-auth --user '#{user}' --#{command} '#{p}' 2>&1`
    end
    return result
  end

  PERMISSION="org.opensuse.yast.permissions.write"
  def check_polkit(sender)
    uid = DBus::SystemBus.instance.proxy.GetConnectionUnixUser(sender)[0]
    user = Etc.getpwuid(uid).name
    begin
      return PolKit.polkit_check(PERMISSION, user) == :yes
    rescue Exception => e
      return false
    end
  end
end

# Set the object path
obj = WebyastPermissionsService.new("/webyast/permissions/Interface")
# Export it!
service.export(obj)

# Now listen to incoming requests
main = DBus::Main.new
main << bus
main.run
