#!/usr/bin/env ruby
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


require 'rubygems'
require 'dbus'
require 'etc'

require 'yaml'

#checking which policykit is used
WEBYAST_CONFIG_FILE = "/etc/webyast/config.yml"
polkit1_enabled = true
if File.exist?(WEBYAST_CONFIG_FILE)
  values = YAML::load(File.open(WEBYAST_CONFIG_FILE, 'r').read)
  polkit1_enabled = false if values["polkit1"] == false
end

if polkit1_enabled
  require 'polkit1'
else
  require 'polkit'
end

# Choose the bus (could also be DBus::session_bus, which is not suitable for a system service)
bus = DBus::system_bus
# Define the service name
service = bus.request_service("webyast.permissions.service")

class WebyastPermissionsService < DBus::Object

  attr_accessor   :polkit1

  def initialize(polkit1_enabled, options={})
    @polkit1 = polkit1_enabled
    super options
  end

  # overriding DBus::Object#dispatch
  # It is needed because dispatch sent just parameters and without sender it is
  # imposible to check permissions of sender. So to avoid it add as last
  # parameter sender id.
  def dispatch(msg)
    msg.params << msg.sender
    super(msg)
  end

  def log(msg)
    f = File.new("/var/log/webyast/permission_service.log", "a", 0600)
    f.write msg
    f.write "\n"
    f.close
  end

  # Create an interface.
  dbus_interface "webyast.permissions.Interface" do
    dbus_method :grant, "out result:as, in permissions:as, in user:s" do |permissions,user,sender|
      result = execute(:grant, permissions, user,sender)
      log "Grant permissions #{permissions.inspect} for user #{user} with result #{result.inspect} " +
          (@polkit1 ? "(Polkit1)" : "(PolicyKit)")
      [result]
    end
    dbus_method :revoke, "out result:as, in permissions:as, in user:s" do |permissions,user,sender|
      result = execute(:revoke, permissions, user,sender)
      log "Revoke permissions #{permissions.inspect} for user #{user} with result #{result.inspect} " +
          (@polkit1 ? "(Polkit1)" : "(PolicyKit)")
      [result]
    end
    dbus_method :check, "out result:as, in permissions:as, in user:s" do |permissions,user,sender|
      result = execute(:check, permissions, user,sender)
      log "check permissions #{permissions.inspect} for user #{user} with result #{result.inspect} " +
          (@polkit1 ? "(Polkit1)" : "(PolicyKit)")
      [result]
    end
  end

USER_REGEX=/\A[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_][ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.-]*[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.$-]?\Z/
USER_WITH_DOMAIN_REGEX=/\A[a-zA-Z0-9][a-zA-Z0-9\-.]*\\[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_][ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.-]*[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.$-]?\Z/
POLKIT_SECTION = "55-webyast.d"

  def execute (command, permissions, user, sender)
    #TODO polkit check, user escaping, perm whitespacing
    return ["NOPERM"] unless check_polkit sender, command
    return ["USER_INVALID"] if invalid_user_name? user 
    result = []
    permissions.each do |p|
      #whitespace check for valid permission string to avoid attack
      unless p.match(/^[a-zA-Z][a-zA-Z0-9.-]*$/)
        result << "permissions have a wrong format"
      else
        case command
          when :grant then
            begin
              if @polkit1
                PolKit1::polkit1_write(POLKIT_SECTION, p, true, user)
                result << "true"
              else
                #whitespace check for valid permission string to avoid attack
                if p.match(/^[a-zA-Z][a-zA-Z0-9.-]*$/)
                  result << `polkit-auth --user '#{user}' --grant '#{p}' 2>&1` # RORSCAN_ITL
                else
                   result << "perm #{p} is INVALID" # XXX tom: better don't include invalif perms here, we do not know what the calling function is doing with it, like displaying it via the browser, passing it to the shell etc.
                end
              end
            rescue Exception => e
              result << e.message
            end   
          when :revoke then
            begin
              if @polkit1
                PolKit1::polkit1_write(POLKIT_SECTION, p, false, user)
                result << "true"
              else
                #whitespace check for valid permission string to avoid attack
                if p.match(/^[a-zA-Z][a-zA-Z0-9.-]*$/)
                  result << `polkit-auth --user '#{user}' --revoke '#{p}' 2>&1` # RORSCAN_ITL
                else
                   result << "perm #{p} is INVALID" # XXX tom: better don't include invalif perms here, we do not know what the calling function is doing with it, like displaying it via the browser, passing it to the shell etc.
                end
              end
            rescue Exception => e
              result << e.message
            end   
          when :check then
            if @polkit1
              if PolKit1::polkit1_check(p, user) == :yes
                result << "yes"
              else
                result << "no"
              end
            else
              uid = DBus::SystemBus.instance.proxy.GetConnectionUnixUser(sender)[0]
              user = Etc.getpwuid(uid).name
              if PolKit.polkit_check(p, user) == :yes
                result << "yes"
              else
                result << "no"
              end
            end
          else 
        end
      end
    end
    return result
  end

  PERMISSION_WRITE="org.opensuse.yast.permissions.write"
  PERMISSION_READ="org.opensuse.yast.permissions.read"
  def check_polkit(sender, command)
    uid = DBus::SystemBus.instance.proxy.GetConnectionUnixUser(sender)[0]
    user = Etc.getpwuid(uid).name
    begin
      case command
        when :grant then
          if @polkit1
            return PolKit1.polkit1_check(PERMISSION_WRITE, user) == :yes
          else
            return PolKit.polkit_check(PERMISSION_WRITE, user) == :yes
          end
        when :revoke then
          if @polkit1
            return PolKit1.polkit1_check(PERMISSION_WRITE, user) == :yes
          else
            return PolKit.polkit_check(PERMISSION_WRITE, user) == :yes
          end
        when :check then
          if @polkit1
            return PolKit1.polkit1_check(PERMISSION_READ, user) == :yes
          else
            return PolKit.polkit_check(PERMISSION_READ, user) == :yes
          end
        else
          return false
      end
    rescue Exception => e
      log "PolKit returns an error: #{e.inspect}"
      return false
    end
  end

  def invalid_user_name? user
    active_directory_enabled = `/usr/sbin/pam-config -q --winbind 2>/dev/null | wc -w`.to_i > 0 # RORSCAN_ITL
    return false if user.match(USER_REGEX)
    return false if active_directory_enabled && user.match(USER_WITH_DOMAIN_REGEX)
    return true
  end
end

# Set the object path
obj = WebyastPermissionsService.new(polkit1_enabled, "/webyast/permissions/Interface")
# Export it!
service.export(obj)

# Now listen to incoming requests
main = DBus::Main.new
main << bus
main.run
