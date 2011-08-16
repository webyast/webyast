#--
# Copyright (c) 2009-2010 Novell, Inc.
# 
# All Rights Reserved.
# 
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License
# as published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
# 
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#++

require 'socket'

def getCurrentIP
  ip, orig, Socket.do_not_reverse_lookup = "", Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily
  
  UDPSocket.open do |s|
    s.connect '64.233.187.99', 1
    ip = s.addr.last
  end
  ensure Socket.do_not_reverse_lookup = orig
  return ip
end

class NetworkController < ApplicationController

  before_filter :login_required
  layout 'main'

  private

  # Initialize GetText and Content-Type.
  init_gettext "webyast-network-ui" 

  public
  def initialize
  end
  
  NETMASK_RANGE = 0..32
  STATIC_BOOT_ID = "static"
  

  # GET /network
  def index
    yapi_perm_check "network.read"
    @ifcs = Interface.find :all
   
    # FIXED: MODULE CRASHED IF BOTH INTERFACES HAS ATTRIBUTE BOOTPROTO !!!
   
    unless @ifcs.nil? || @ifcs.empty? #No network interfaces found
      
      unless @ifcs.length == 1
        logger.debug "***** More than one interface is attached -> #{ @ifcs.length } *****"
        Rails.logger.error @ifcs.to_hash.inspect
        
        @ifcs.each do |id, interface| 
          unless interface.bootproto.nil?
            logger.error "** Interface #{interface.id} is active\n"
            ifc = Interface.find(id)
            @iface = id
          end
        end
      end  
   
    else
      logger.error "***ERROR: No network interface found!"
    end

    ifc = Interface.find @iface
    return false unless ifc
    
    # TODO use rescue_from "AR::Base not found..."
    # http://api.rubyonrails.org/classes/ActiveSupport/Rescuable/ClassMethods.html
    
    hn = Hostname.find 
    return false unless hn
    
    dns = Dns.find 
    return false unless dns
    
    rt = Route.find "default"
    return false unless rt
    
    @write_permission = yapi_perm_granted?("network.write")

    @conf_mode = ifc.bootproto
    @conf_mode = STATIC_BOOT_ID if @conf_mode.blank?

    if @conf_mode == STATIC_BOOT_ID
      ipaddr = ifc.ipaddr
    else
      ipaddr = "/"
    end
    
    @ip, @netmask = ipaddr.split "/"
    # when detect PREFIXLEN with leading "/"
    if ifc.bootproto == STATIC_BOOT_ID && NETMASK_RANGE.include?(@netmask.to_i)
      @netmask = "/"+@netmask
      Rails.logger.error "\n*** set netmask if static and netmask in range #{@netmask} \n"
    end    
 
    @name = hn.name
    @domain = hn.domain
    
    @dhcp_ip = getCurrentIP;
    
    @dhcp_hostname_enabled = hn.respond_to?("dhcp_hostname")
    @dhcp_hostname = @dhcp_hostname_enabled && hn.dhcp_hostname == "1"
    
    @nameservers = dns.nameservers
    @searchdomains = dns.searches
    @default_route = rt.via
 
    @conf_modes = {_("Manual")=>STATIC_BOOT_ID, _("Automatic")=>"dhcp"}
    @conf_modes[@conf_mode] =@conf_mode unless @conf_modes.has_value? @conf_mode
  end



  # PUT /users/1
  # PUT /users/1.xml
  def update
    dirty = false
    dirty_ifc = false
    
    ### HOSTANE ###
    
    hn = Hostname.find
    
    return false unless hn
    dirty = true unless (hn.name == params["hostname"] && hn.domain == params["domain"])
    
    logger.info "\n*** INFO: dirty after hostname: #{dirty}\n"
    
    hn.name   = params["hostname"]
    hn.domain = params["domain"]
    Rails.logger.error "### DEBUG: set hostname #{hn.name} \n"
    Rails.logger.error "### DEBUG: set domain #{hn.domain} \n"

    if params["dhcp_hostname_enabled"] == "true"
      #params["dhcp_hostname"]==nil ? params["dhcp_hostname"]="0" : pass
      #Set dirty to true (bnc#692594)
      dirty = true 
      hn.dhcp_hostname = params["dhcp_hostname"] || "0"
      Rails.logger.error "### DEBUG: set dhcp_hostname #{hn.dhcp_hostname} \n"
      
      logger.info "\n*** INFO: dirty after dhcp_hostname: #{dirty}\n"
    end

    ### END HOSTANE ###
    
    
    ### DNS ###

    dns = Dns.find
    return false unless dns
    
    # Simply comparing empty array and nil would wrongly mark it dirty,
    # so at first test emptiness
    #FIXME repair it when spliting of param is ready
    
    
    unless (dns.nameservers.empty? && params["nameservers"].blank?)
      dirty = true unless dns.nameservers == (params["nameservers"]||"").split
    end
    
    unless (dns.searches.empty? && params["searchdomains"].blank?)
      dirty = true unless dns.searches == (params["searchdomains"]||"").split
    end

    logger.info "\n*** INFO: dirty after  dns: #{dirty}\n"
    
    # now the model contains arrays but for saving
    # they need to be concatenated because we can't serialize them
    # FIXME: params bellow should be arrays    
    
    
    Rails.logger.error "### ERROR: set dns_nameservers #{params["nameservers"]} \n"
    Rails.logger.error "### ERROR: set dns_searches #{params["searchdomains"]} \n"
    
    dns.nameservers = params["nameservers"].nil? ? [] : params["nameservers"].split
    dns.searches    = params["searchdomains"].nil? ? [] : params["searchdomains"].split


    Rails.logger.error "### DEBUG: set dns_nameservers #{dns.nameservers.inspect} \n"
    Rails.logger.error "### DEBUG: set dns_searches #{dns.searches.inspect} \n"
    
    ### END DNS ### 
    

    ### INTERFACE ###

    ifc = Interface.find params["interface"]
    return false unless ifc
    
    dirty_ifc = true unless (ifc.bootproto == params["conf_mode"])
    logger.info "\n*** INFO: dirty after interface config: #{dirty}\n"
    
    ifc.bootproto=params["conf_mode"]
    
    if ifc.bootproto == STATIC_BOOT_ID
      #ip addr is returned in another state then given, but restart of static address is not problem
      if ((ifc.ipaddr||"").delete("/")!=params["ip"]+(params["netmask"]||"").delete("/"))
        dirty_ifc = true
        ifc.ipaddr=params["ip"]+"/"+params["netmask"].delete("/")
        Rails.logger.error "### DEBUG: set interface IPADDR #{ifc.ipaddr} \n"
      end
    end
   
   
   ### END INTERFACE ###
   
   
   ### ROUTE ###
   
   rt = Route.find "default"
   return false unless rt
    
   dirty = true unless rt.via == (params["default_route"] || "")

   rt.via = params["default_route"]
   Rails.logger.error "### DEBUG: set default_route #{rt.via} \n"

   logger.info "*** INFO: dirty after default routing: #{dirty}"

   ### END ROUTE ###
    
   
   
    # this is not transaction!
    # if any *.save failed, the previous will be applied
    # FIXME JR: I think that if user choose dhcp not all settings should be written
    
    
    Rails.logger.error "\n\nPARAMS #{params.inspect}\n\n"
    
    
    if dirty||dirty_ifc
      Rails.logger.error "\n==== BEFORE SAVE ===="
      Rails.logger.error "### HOSTNAME #{hn.inspect}"
      Rails.logger.error "### DNS #{dns.inspect}"    
      Rails.logger.error "### ROUTE #{rt.inspect}"
      Rails.logger.error "==== END ===="
    
      rt.save
      dns.save
      hn.save
    
      # write interfaces (and therefore restart network) only when interface settings changed (bnc#579044)
      if dirty_ifc
        Rails.logger.error "\n==== BEFORE SAVE ===="
        Rails.logger.error "### INTERFACE #{ifc.inspect}\n"
        ifc.save
      end
    end


     #write to avoid confusion, with another string
     flash[:notice] = _('Network settings have been written.')
     redirect_success
  end
end
