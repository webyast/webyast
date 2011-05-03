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
# Resource class
#

class Resource < BaseModel::Base
  require 'resource_registration'
  attr_accessor :policy, :interface, :href, :singular, :cache_enabled, :cache_priority, :cache_reload_after, :cache_arguments

  def initialize (interface, impl_hash)
    @interface = interface
    @policy    = impl_hash[:policy] || ""
    @singular  = impl_hash[:singular]
    @href = "/#{impl_hash[:controller]}"
    @cache_enabled = impl_hash[:cache_enabled]
    @cache_priority = impl_hash[:cache_priority]
    @cache_reload_after = impl_hash[:cache_reload_after]
    @cache_arguments = eval(impl_hash[:cache_arguments]) #this is save cause it is defined in a configuration file
  end

  def self.find(what)
    # There is no reload mechansim for the cache. So fetch it directly
    return Rails.cache.fetch("resource:find:#{what}") {
      case what
        when :all then
          resources = []
          ResourceRegistration.resources.sort.each do |interface,implementations|
            implementations.each do |impl|
              resources << new(interface,impl)
            end
          end
          resources
        else
          implementations = ResourceRegistration.resources[what]
          implementations ? new(what, implementations.first) : nil
      end
    }
  end
end
