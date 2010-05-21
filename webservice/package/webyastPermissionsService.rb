#!/usr/bin/env ruby

require 'dbus'

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

  # Create an interface.
  dbus_interface "webyast.permissions.Interface" do
    dbus_method :grant, "out result:as, in permissions:as, in user:s" do |permissions,user,sender|
      execute "grant", permissions, user,sender
    end
    dbus_method :revoke, "out result:as, in permissions:as, in user:s" do |permissions,user,sender|
      execute "revoke", permissions, user,sender
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
    result
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
