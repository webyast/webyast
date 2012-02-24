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

    @type = params[:id][0..(params[:id].size-2)] || "eth"
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
      format.json { render :json => @ifc }
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

    @ifc = Interface.new({"type"=>params[:type], "bootproto"=>"dhcp", "startmode"=>"auto", "bridge_ports"=>[]}, "#{@type}#{@number}")

    #@dhcp_hostname_enabled = @hostname.respond_to?("dhcp_hostname")

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @ifc }
    end

  end

  def create
    authorize! :write, Network

    Rails.logger.error "Params #{params.inspect}"

    hash = {}
    hash["type"] = params[:type] if  params[:type]
    hash["bootproto"] = params[:bootproto]
    hash["ipaddr"] = params[:ipaddr] || ""
    hash["vlan_id"] = params[:vlan_id] if  params[:vlan_id]
    hash["vln_etherdevice"] = params[:vlan_etherdevice] if  params[:vlan_etherdevice]
    hash["bridge_ports"] = params["bridge_ports"].map{|k,v| k if v=="1"}.compact.join(" ").to_s if params["bridge_ports"]

    ifc = Interface.new(hash, "#{params["type"]}#{params["number"]}")
    ifc.save

    redirect_to :controller => "network", :action => "index"
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    authorize! :write, Network

    dirty_hostname = false
    dirty_dns = false
    dirty_route = false
    dirty_ifc = false

    network = Network.find


    ### HOSTANEM ###
    hostname = network["hostname"]

    if hostname.name != params["hostname"] && hostname.domain != params["domain"]
      hostname.name   = params["hostname"]
      hostname.domain = params["domain"]

      dirty_hostname = true
    end

    if params["dhcp_hostname_enabled"] == "true"
      hostname.dhcp_hostname = params["dhcp_hostname"] || "0"
      #params["dhcp_hostname"]==nil ? params["dhcp_hostname"]="0" : pass

      dirty_hostname = true #Set dirty to true (bnc#692594)
    end
    ### END HOSTNAME ###


    ### DNS ###
    dns = network["dns"]

    # Simply comparing empty array and nil would wrongly mark it dirty,
    # so at first test emptiness
    #FIXME repair it when spliting of param is ready

    unless (dns.nameservers.empty? && params["nameservers"].blank?)
      dirty_dns = true unless dns.nameservers == (params["nameservers"]||"").split
    end

    unless (dns.searches.empty? && params["searchdomains"].blank?)
      dirty_dns = true unless dns.searches == (params["searchdomains"]||"").split
    end

    # now the model contains arrays but for saving
    # they need to be concatenated because we can't serialize them
    # FIXME: params bellow should be arrays

    dns.nameservers = params["nameservers"].nil? ? [] : params["nameservers"].split
    dns.searches    = params["searchdomains"].nil? ? [] : params["searchdomains"].split
    ### END DNS ###


    ### INTERFACE ###
    ifc = Interface.find params["interface"]
    ifc.type = params["type"]

    dirty_ifc = true unless (ifc.bootproto == params["bootproto"])

    ifc.bootproto = params["bootproto"]
    ifc.ipaddr = params["ipaddr"] || ""

    if ifc.bootproto == STATIC_BOOT_ID
      #ip addr is returned in another state then given, but restart of static address is not problem
      if ((ifc.ipaddr).delete("/")!= params["ip"] + (params["netmask"]||"").delete("/"))
        ifc.ipaddr = params["ip"] + "/" + params["netmask"].delete("/")
        dirty_ifc = true
      end
    end

    if params[:vlan_id] && ifc.vlan_id != params[:vlan_id]
      ifc.vlan_id = params[:vlan_id]
      dirty_ifc = true
    end

    if params[:vlan_etherdevice] && ifc.vlan_etherdevice !=  params[:vlan_etherdevice]
      ifc.vlan_etherdevice = params[:vlan_etherdevice]
      dirty_ifc = true
    end

    if params["bridge_ports"] && ifc.bridge_ports != params["bridge_ports"]
      ifc.bridge_ports = params["bridge_ports"].map{|k,v| k if v=="1"}.compact.join(' ').to_s
      dirty_ifc = true
    end
   ### END INTERFACE ###


   ### ROUTE ###
   route = network["routes"]

   if params["default_route"] && route.via != params["default_route"]
     route.via = params["default_route"]
     dirty_route = true
   end
   ### END ROUTE ###


    if dirty_route
      Rails.logger.error "*** ROUTE is dirty #{route.inspect}\n"
      route.save
    end

    if dirty_dns
      Rails.logger.error "*** DNS is dirty #{dns.inspect}\n"
      dns.save
    end

    if dirty_hostname
      Rails.logger.error "*** HOSTNAME is dirty #{hostname.inspect}\n"
      hostname.save
    end

    # write interfaces (and therefore restart network) only when interface settings changed (bnc#579044)
    if dirty_ifc
      Rails.logger.error "\n================================"
      Rails.logger.error "### HOSTNAME #{hostname.inspect}\n"
      Rails.logger.error "### DNS #{dns.inspect}\n"
      Rails.logger.error "### ROUTE #{route.inspect}\n"
      Rails.logger.error "### INTERFACE #{ifc.inspect}\n"
      Rails.logger.error "=================================\n"

      route.save
      dns.save
      hostname.save
      ifc.save
    end

     flash[:notice] = _('Network settings have been written.')
     redirect_to :controller => "network", :action => "index"
  end
end
