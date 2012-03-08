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
# Permission class
#
require 'exceptions'
require 'yast_cache'
require "yast_service"
require 'yast/config'

class Permission
  #list of hash { :name => id, :granted => boolean, :description => string (optional)}
  attr_reader :permissions

private

  def self.get_cache_timestamp
    lst = []
    if YaST::POLKIT1
      lst = [
        # policies
        File.mtime('/usr/share/polkit-1/'),
        # default
        File.mtime('/var/lib/polkit-1/'),
        # explicit user authorizations
        File.mtime('/etc/polkit-1'),
      ]
    else
      lst = [
        # the global config file
        File.mtime('/etc/PolicyKit/PolicyKit.conf'),
        # policies
        File.mtime('/usr/share/PolicyKit/policy/'),
        # explicit user authorizations
        File.mtime('/var/lib/PolicyKit/'),
        # default overrides
        File.mtime('/var/lib/PolicyKit-public/'),
      ]
    end

    lst.compact!
    lst.max.to_i
  end

  def self.cache_valid
    return false unless YastCache.active
    cache_id = 'permissions::timestamp'
    #cache contain string as it is only object supported by all caching backends
    cache_timestamp = Rails.cache.read(cache_id).to_i
    current_timestamp = self.get_cache_timestamp

    if !cache_timestamp
      Rails.cache.write(cache_id, current_timestamp.to_s)
    elsif cache_timestamp < current_timestamp
      Rails.logger.debug "#### Permissions cache expired"
      Rails.cache.write(cache_id, current_timestamp.to_s)
      return false
    end
    return true
  end

  def self.reset(user)
    Rails.cache.delete("permission:#{user}")
  end


public

  def initialize
    @permissions = []
  end

  def self.set_permissions(user,permissions)
    YastService.lock #locking for other thread
    service = dbus_obj

    #FIXME vendor permission with different prefix is not reset
    all_perm = filter_nonsuse_permissions all_actions.split(/\n/)

    #reset all permissions
    response = service.revoke all_perm, user
    #Rails.logger.info "*** Revoke permissions for user #{user} perms: #{all_perm.inspect} \n with result:\n#{response.inspect}"

    unless permissions.empty?
      response = service.grant permissions, user
      #Rails.logger.info "*** Grant permissions for user #{user} :\n#{permissions.inspect}\nwith result #{response.inspect}"
    end

    YastService.unlock #unlocking for other thread
    self.reset(user)
  end

  def self.find(type,restrictions={})
    filters = {}
    ret = {}
    #filter out only needed parameters
    restrictions.each {|key, value|
      filters[key.to_sym] = value if %w( filter with_description user_id ).index(key.to_s)
    }
    perm_id = "permission:#{filters[:user_id]}"
    self.reset(filters[:user_id] || "") unless self.cache_valid
    if filters.size == 1 && filters.has_key?(:user_id)
      #cache the "common" way of asking permission "has user xyz the permission.."
      ret = Rails.cache.fetch(perm_id) {
        permission = Permission.new
        permission.load_permissions(filters)
        permission.permissions
      }      
    else
        permission = Permission.new
        permission.load_permissions(filters)
        ret = permission.permissions
    end
    if (type != :all)
      ret.delete_if { |perm| !perm[:id].include? type }
    else
      ret
    end
  end

  def save
    raise "Unimplemented"
  end

  def load_permissions(options)
    semiresult = Permission.all_actions.split(/\n/)
    semiresult = Permission.filter_nonsuse_permissions semiresult
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
    YastService.lock #locking for other thread

    @permissions.collect! do |perm|
      begin
        service = Permission.dbus_obj
        if service.check( [perm[:id]], user )[0][0] == "yes"
          perm[:granted] = true
          Rails.logger.debug "Action: #{perm[:id]} User: #{user} Result: ok"
        else
          perm[:granted] = false
          Rails.logger.debug "Action: #{perm[:id]} User: #{user} Result: NOT granted"
        end
      rescue RuntimeError => e
        Rails.logger.info e
        YastService.unlock #unlocking for other thread
        if e.message.include?("does not exist")
          raise InvalidParameters.new :user_id => "UNKNOWN"
        else
          raise PolicyKitException.new(e.message, user, perm[:id])
        end
      end
      perm
    end

    YastService.unlock #unlocking for other thread
  end

  def get_description (action)
    if YaST::POLKIT1
      desc = `/usr/bin/pkaction --action-id #{action} | grep description: |  sed 's/description://g'`
    else
      desc = `polkit-action --action #{action} | grep description: | sed 's/^description:[:space:]*\\(.\\+\\)$/\\1/'`
    end
    desc.strip!
    desc
  end

  def self.all_actions
    if YaST::POLKIT1
      `/usr/bin/pkaction` # RORSCAN_ITL
    else
      `/usr/bin/polkit-action` # RORSCAN_ITL
    end
  end


  def self.filter_nonsuse_permissions (str)
    suse_string = "org.opensuse.yast"
    str.select{ |s|
      s.include?(suse_string) &&
      !s.include?(suse_string + ".scr") &&
      !s.include?(suse_string +".module-manager")
    }
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
