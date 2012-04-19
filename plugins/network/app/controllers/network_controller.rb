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

  def index
    authorize! :read, Network

    @ifcs = Interface.find(:all)
    @physical = @ifcs.select{|k, i| i if k.match("eth")}
    @virtual = @ifcs.select{|k, i| i unless k.match("eth")}

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @ifcs }
    end
  end

  def edit
    authorize! :read, Network

    network = Network.find
    
    @hostname = network["hostname"]
    @dns = network["dns"]
    @routes = network["routes"]

    @ifcs = network["interfaces"]
    @ifc = @ifcs[params[:id]]

    @type = params[:id][0..(params[:id].size-2)] || "eth"
    @number = @ifcs.select{|id, iface| id if id.match(@type)}.count
    @physical = @ifcs.select{|k, i| i if k.match("eth")}


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

    @ifc = Interface.new({"type"=>params[:type], "bootproto"=>"dhcp", "startmode"=>"auto"}, "#{@type}#{@number}")

    #@dhcp_hostname_enabled = @hostname.respond_to?("dhcp_hostname")

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @ifc }
    end

  end

  def create
    authorize! :write, Network

    hash = {}
    hash["type"] = params[:type] if  params[:type]
    hash["bootproto"] = params[:bootproto]
    hash["ipaddr"] = params[:ipaddr] || ""
    hash["vlan_id"] = params[:vlan_id] if  params[:vlan_id]
    hash["vlan_etherdevice"] = params[:vlan_etherdevice] if  params[:vlan_etherdevice]
    hash["bridge_ports"] = params["bridge_ports"].map{|k,v| k if v=="1"}.compact.join(' ').to_s || "" if params["bridge_ports"]
    hash["bond_slaves"] = params["bond_slaves"].map{|k,v| k if v=="1"}.compact.join(' ').to_s if params["bond_slaves"]

    if params["bond_mode"] && params["bond_miimon"]
      bond_option = "#{params["bond_mode"]} #{params["bond_miimon"].gsub(/ /,'')}"
      hash["bond_option"] = bond_option
    end
    
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

    unless (dns.nameservers.empty? && params["nameservers"].blank?)
      dirty_dns = true unless dns.nameservers == (params["nameservers"]||"").split
    end

    unless (dns.searches.empty? && params["searchdomains"].blank?)
      dirty_dns = true unless dns.searches == (params["searchdomains"]||"").split
    end

    dns.nameservers = params["nameservers"].nil? ? [] : params["nameservers"].split
    dns.searches    = params["searchdomains"].nil? ? [] : params["searchdomains"].split
    ### END DNS ###


    ### INTERFACE ###
    ifc = Interface.find params["interface"]
    ifc.type = params["type"]

    dirty_ifc = true unless (ifc.bootproto == params["bootproto"])

    ifc.bootproto = params["bootproto"]
    
    if ifc.bootproto == STATIC_BOOT_ID
        ifc.ipaddr = "#{params["ip"]}/#{ifc.netmask_to_cidr(params["netmask"])}"
        dirty_ifc = true
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
      ifc.bridge_ports = params["bridge_ports"].map{|k,v| k if v=="1"}.compact.join(' ').to_s || ""
      dirty_ifc = true
    end
    
    if params["bond_slaves"] && ifc.bond_slaves != params["bond_slaves"]
      ifc.bond_slaves = params["bond_slaves"].map{|k,v| k if v=="1"}.compact.join(' ').to_s
      dirty_ifc = true
    end
    
    if params["bond_mode"] && params["bond_miimon"]
      bond_option = "#{params["bond_mode"]} #{params["bond_miimon"].gsub(/ /,'')}"
      if ifc.bond_option != bond_option
        ifc.bond_option = bond_option
        dirty_ifc = true
       end
    end
    
    if params["bond_mode"] && ifc.bond_option != params["bond_mode"]
       ifc.bond_option
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
      route.save
      dns.save
      hostname.save
      ifc.save
    end

     flash[:notice] = _('Network settings have been written.')
     redirect_to :controller => "network", :action => "index"
  end

  def destroy
    authorize! :write, Network

    ifc = Interface.find params[:id]
    ret = ifc.destroy
    redirect_to :controller => "network", :action => "index"
  end

end
