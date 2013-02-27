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
    @physical = @ifcs.select{|k, i| i if k.match(/eth|wlan|ath/)}
    @virtual = @ifcs.select{|k, i| i unless k.match(/eth|wlan|ath/)}

    respond_to do |format|
      format.html # index.html.erb
      format.xml { render :xml => @ifcs.values.to_xml( :root => "interfaces", :dasherize => false) }
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
    occupied_numbers =  @ifcs.select{|id, iface| id if id.match(@type)}.map {|id,iface| id.sub(/\A\D+(\d+)\Z/,'\\1').to_i}
    @available_numbers = (0..9).to_a - occupied_numbers
    @physical = @ifcs.select{|k, i| i if k.match(/eth|wlan|ath/)}

    @dhcp_hostname_enabled = @hostname.dhcp_hostname_enabled

    respond_to do |format|
      format.html
      format.xml { render :xml => @ifc.to_xml(:dasherize => false) }
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
    occupied_numbers =  @ifcs.select{|id, iface| id if id.match(@type)}.map {|id,iface| id.sub(/\A\D+(\d+)\Z/,'\\1').to_i}
    @available_numbers = (0..9).to_a - occupied_numbers
    @physical = @ifcs.select{|k, i| i if k.match(/eth|wlan/)}

    @ifc = Interface.new({"type"=>params[:type], "bootproto"=>"dhcp", "startmode"=>"auto"}, "#{@type}#{@available_numbers.first}")

    @dhcp_hostname_enabled = @hostname.dhcp_hostname_enabled

    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @ifc.to_xml(:dasherize => false) }
      format.json { render :json => @ifc }
    end

  end

  def create
    # create is handled via update
    @create = true
    update
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

    ### HOSTNAME ###
    hostname = network["hostname"]

    if hostname.name != params["hostname"] || hostname.domain != params["domain"]
      hostname.name   = params["hostname"]
      hostname.domain = params["domain"]

      dirty_hostname = true
    end

    # check if dhcp hostname value changed, dhcp_hostname_enabled has "true", "false" value, dhcp_hostname is "1" or nil
    old_dhcp_hostname = params["dhcp_hostname_enabled"] == "true"
    new_dhcp_hostname = params["dhcp_hostname"].present?
    if ( old_dhcp_hostname != new_dhcp_hostname )
      hostname.dhcp_hostname = params["dhcp_hostname"] || "0"
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

    # create Interface object (depending on update/create request)
    if @create
      data = {}
      data["type"] = params[:type] if params[:type]

      ifc = Interface.new(data, "#{params["type"]}#{params["number"]}")

      # make sure the new interface is saved
      dirty_ifc = true
    else
      ifc = Interface.find params["interface"]
      ifc.type = params["type"]
    end

    dirty_ifc = true unless (ifc.bootproto == params["bootproto"])

    ifc.bootproto = params["bootproto"]
    
    if ifc.bootproto == STATIC_BOOT_ID
        ifc.ipaddr = "#{params["ip"]}/#{ifc.netmask_to_cidr(params["netmask"])}"
        dirty_ifc = true
    end

    if params[:vlan_id] && ifc.vlan_id != params[:vlan_id]
      ifcs = Interface.find :all
      used_vlan_id = ifcs.find {|k, v| k.start_with?("vlan") && v.vlan_id == params[:vlan_id]}

      if used_vlan_id.present?
        flash[:error] = _("VLAN ID %s is already used by interface %s") % [params[:vlan_id], used_vlan_id.first]

        if @create
          redirect_to :action => :new, :type => "vlan"
        else
          redirect_to :action => :edit, :id => params["interface"]
        end

        return
      end

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
      # bnc#790219 All bonded (selected) slaves need to be configured with bootproto=none
      # use try, because create is also used for other types, that doesn't have parameter bond_slaves
      params["bond_slaves"].each do |slave, selected|
        next if selected != "1"

        slave_ifc = Interface.find slave
        unless slave_ifc
          Rails.logger.error "Cannot find slave interface #{slave}"
          flash[:error] = _("Cannot find interface %s to be bonded.") % slave
          redirect_to :controller => "network", :action => "index" and return
        end
        Rails.logger.info "Found slave #{slave_ifc.inspect}"

        # Already correctly configured
        next if slave_ifc.bootproto == "none"

        # Configured but incorrectly for bonding
        if slave_ifc.bootproto
          Rails.logger.error "User tries to bond configured interface #{slave} with config mode #{slave_ifc.bootproto}"
          flash[:error] = _("Cannot bond interface %s. Its configuration mode must be %s instead of %s.") % [slave, 'NONE', slave_ifc.bootproto.upcase]
          redirect_to :controller => "network", :action => "index" and return
        end

        Rails.logger.info "Configuring interface #{slave}"
        # Only network cards can be without any configuration
        slave_ifc.type = "eth"
        slave_ifc.bootproto = "none"
        unless slave_ifc.save
          Rails.logger.error "Cannot save #{slave_ifc.inspect} configuration"
          flash[:error] = _("Cannot save %s configuration. Please, set it up with configuration mode %s before bonding.") % [slave, 'NONE']
          redirect_to :controller => "network", :action => "index" and return
        end
      end

      ifc.bond_slaves = params["bond_slaves"].map{|k,v| k if v=="1"}.compact.join(' ').to_s
      dirty_ifc = true
    end

    if ifc.type == "bond" && ifc.bond_slaves.blank?
      flash[:error] = _("Bond interface requires at least one slave interface.")

      if @create
        redirect_to :action => :new, :type => "bond"
      else
        redirect_to :action => :edit, :id => params["interface"]
      end

      return
    end
    
    if params["bond_mode"] && params["bond_miimon"]
      bond_option = "#{params["bond_mode"]} #{params["bond_miimon"].gsub(/ /,'')}"
      if ifc.bond_option != bond_option
        ifc.bond_option = bond_option
        dirty_ifc = true
       end
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
