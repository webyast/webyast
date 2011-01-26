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


#
# Permission class
#
require 'exceptions'
require 'polkit'

class Permission
#list of hash { :name => id, :granted => boolean, :description => string (optional)}
  attr_reader :permissions

  def initialize
    @permissions = []
  end

  def self.set_permissions(user,permissions)
    service = dbus_obj
#FIXME vendor permission with different prefix is not reset
    all_perm = filter_nonsuse_permissions all_actions.split(/\n/)
    #reset all permissions
    response = service.revoke all_perm, user
    Rails.logger.info "revoke perms for user #{user} perms: #{all_perm.inspect} \n with result:\n#{response.inspect}"
    unless permissions.empty?
      response = service.grant permissions, user
      Rails.logger.info "grant perms for user #{user} :\n#{permissions.inspect}\nwith result #{response.inspect}"
      #TODO convert response to exceptions in case of error
    end
  end

  def self.find(type,restrictions={})
    permission = Permission.new
    permission.load_permissions restrictions
    return permission.permissions
  end

  def save
    raise "Unimplemented"
  end

  def load_permissions(options)
    semiresult = Permission.all_actions.split(/\n/)
    if (options[:filter])
      semiresult.delete_if { |perm| !perm.include? options[:filter] }
    else
      semiresult = Permission.filter_nonsuse_permissions semiresult
    end
  @permissions = semiresult.map do |value|
      ret = {
        :id => value,
        :granted => false
      }
			ret[:description] = get_description(value) if options[:with_description]
			ret
    end
    user = options[:user_id]
    mark_granted_permissions_for_user user if user
  end

private
  def mark_granted_permissions_for_user(user)
    @permissions.collect! do |perm| 
      begin
        if PolKit.polkit_check( perm[:id], user) == :yes
          perm[:granted] = true
          Rails.logger.debug "Action: #{perm[:id]} User: #{user} Result: ok"
        else
          perm[:granted] = false
          Rails.logger.debug "Action: #{perm[:id]} User: #{user} Result: NOT granted"
        end
      rescue RuntimeError => e
        Rails.logger.info e
        if e.message.include?("does not exist")
          raise InvalidParameters.new :user_id => "UNKNOWN" 
        else
          raise PolicyKitException.new(e.message, user, perm[:id])
        end
      end
      perm
    end
  end



	def get_description (action)
		desc = `polkit-action --action #{action} | grep description: | sed 's/^description:[:space:]*\\(.\\+\\)$/\\1/'`
		desc.strip!
		desc
  end

public
  def self.all_actions
    `/usr/bin/polkit-action` # RORSCAN_ITL
  end

  SUSE_STRING = "org.opensuse.yast"
  def self.filter_nonsuse_permissions (str)
    str.select{ |s|
      s.include?(SUSE_STRING) &&
        !s.include?(SUSE_STRING+".scr") &&
        !s.include?(SUSE_STRING+".module-manager")}
  end

  def self.dbus_obj
    bus = DBus.system_bus # RORSCAN_ITL
    ruby_service = bus.service("webyast.permissions.service")
    obj = ruby_service.object("/webyast/permissions/Interface")
    obj.introspect
    obj.default_iface = "webyast.permissions.Interface"
    obj
  end
end
