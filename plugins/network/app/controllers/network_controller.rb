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

class NetworkController < ApplicationController
  NETMASK_RANGE = 0..32
  STATIC_BOOT_ID = "static"

  # GET /network
  def index
    # TODO: NO INTERFACE FOUND!!!
    authorize! :read, Network
    @ifcs = Interface.find(:all)
    @physical = @ifcs.select{|k, i| i if k.match("eth")}
    @virtual = @ifcs.select{|k, i| i unless k.match("eth")}

    Rails.logger.error "*** NETWORK #{@ifcs.inspect}"

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @ifcs }
    end
  end

  def edit
    authorize! :read, Network

    # moved to model ????????????
    #@dhcp_hostname_enabled = @hostname.respond_to?("dhcp_hostname")
    #@dhcp_hostname = @dhcp_hostname_enabled && @hostname.dhcp_hostname == "1"

    network = Network.find
    @hostname = network["hostname"]
    @dns = network["dns"]
    @routes = network["routes"]

    @ifcs = network["interfaces"]
    @ifc = @ifcs[params[:id]]

    @type = params[:id][0..(params[:id].size-2)]
    @number = @ifcs.select{|id, iface| id if id.match(@type)}.count
    @physical = @ifcs.select{|k, i| i if k.match("eth")}


    # <<<< TODO: FINDE A BETTER WAY FOR IP HANDLIND
    #ipaddr = (@bootproto == STATIC_BOOT_ID)? @ifc.ipaddr || "/" : "/"
    #@ip, @netmask = @ifc.ipaddr.split "/"

#    debugger
     # when detect PREFIXLEN with leading "/"
#    if @ifc.bootproto == STATIC_BOOT_ID && NETMASK_RANGE.include?(@netmask.to_i)
#      @netmask = "/" + @netmask
#      Rails.logger.error "\n*** set netmask if static and netmask in range #{@netmask} \n"
#    end

    # >>>>>

    respond_to do |format|
      format.html
      format.json { render :json => @interface }
    end
  end

  def new
    authorize! :write, Network

    network = Network.find
    @hostname = network["hostname"]
    @ifcs = network["interfaces"]
    @dns = network["dns"]
    @routes = network["routes"]

    @type = params[:type]
    @number = @ifcs.select{|id, iface| id if id.match(@type)}.count
    @physical = @ifcs.select{|k, i| i if k.match("eth")}

    @ifc = Interface.new({"bootproto"=>"dhcp", "startmode"=>"auto"}, "#{@type}#{@number}")

    #@dhcp_hostname_enabled = @hostname.respond_to?("dhcp_hostname")

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @interface }
    end

  end

  def create
    authorize! :write, Network

    Rails.logger.error "Params #{params.inspect}"

    id = params["interface"]
    hash = {}
    hash["bootproto"] = params[:bootproto]
    hash["ipaddr"] = params[:ipaddr] || ""
    hash["vlan_id"] = params[:vlan_id] if  params[:vlan_id]
    hash["vlan_etherdevice"] = params[:vlan_etherdevice] if  params[:vlan_etherdevice]

    ifc = Interface.new(hash, params["interface"])
    Rails.logger.error "**** New interface: #{ifc.inspect}"
    ifc.save

    redirect_to :controller => "network", :action => "index"
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    authorize! :write, Network

    dirty = false
    dirty_ifc = false


    # *** SET HOSTNAME VALUES *** #

    hostname = Hostname.find
    return false unless hostname

    # Check for hostname changes
    if hostname.name != params["hostname"] && hostname.domain != params["domain"]
      dirty = true
      hostname.name   = params["hostname"]
      hostname.domain = params["domain"]

      Rails.logger.info "\n*** INFO: Network configuration is dirty after hostname #{params["hostname"].inspect}\n"
    end

    if params["dhcp_hostname_enabled"] == "true"
      #params["dhcp_hostname"]==nil ? params["dhcp_hostname"]="0" : pass
      #Set dirty to true (bnc#692594)
      dirty = true
      hostname.dhcp_hostname = params["dhcp_hostname"] || "0"
      Rails.logger.info "\n*** INFO: Network configuration is dirty after dhcp_hostname: #{hostname.inspect}\n"
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


    dirty_ifc = true
    #dirty_ifc = true unless (ifc.bootproto == params["bootproto"]) ONLY FOR DEBUG

    logger.info "\n*** INFO: dirty after interface config: #{dirty}\n"

    ifc.bootproto = params["bootproto"]
    ifc.ipaddr = params["ipaddr"] || ""
    ifc.vlan_id = params[:vlan_id] if params[:vlan_id]
    ifc.vlan_etherdevice = params[:vlan_etherdevice] if params[:vlan_etherdevice]


    if ifc.bootproto == STATIC_BOOT_ID
      #ip addr is returned in another state then given, but restart of static address is not problem
      if ((ifc.ipaddr).delete("/")!= params["ip"] + (params["netmask"]||"").delete("/"))
        dirty_ifc = true
        ifc.ipaddr = params["ip"] + "/" + params["netmask"].delete("/")
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
      Rails.logger.error "### HOSTNAME #{hostname.inspect}"
      Rails.logger.error "### DNS #{dns.inspect}"
      Rails.logger.error "### ROUTE #{rt.inspect}"
      Rails.logger.error "==== END ===="

      rt.save
      dns.save
      hostname.save

      # write interfaces (and therefore restart network) only when interface settings changed (bnc#579044)
      if dirty_ifc
        Rails.logger.error "\n==== BEFORE SAVE ===="
        Rails.logger.error "### INTERFACE #{ifc.inspect}\n"
        ifc.save
      end
    end


     #write to avoid confusion, with another string
     flash[:notice] = _('Network settings have been written.')
     redirect_to :controller => "network", :action => "index"
  end
end
