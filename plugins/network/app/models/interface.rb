#--
# Copyright (c) 2009 Novell, Inc.
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
# = Network interface model
# Provides set and gets resources from YaPI network module.
# Main goal is handle YaPI specific calls and data formats. Provides cleaned
# and well defined data.

require 'base'
require 'ipaddr'
require "open3"

class Interface < BaseModel::Base

  IPADDR_REGEX = /([0-9]{1,3}.){3}[0-9]{1,3}/
  IP_IPADDR_REGEX = /inet (#{IPADDR_REGEX})/

  attr_accessor :id, :bootproto, :ipaddr, :vendor, :type
  attr_accessor :bridge_ports # default: set BRIDGE to "yes" in NETWORK.pm
  attr_accessor :vlan_etherdevice, :vlan_id
  attr_accessor :bond_mode, :bond_miimon, :bond_option, :bond_slaves

  $bond_options = [
    "mode=balance-rr",
    "mode=active-backup",
    "mode=balance-xor",
    "mode=broadcast",
    "mode=802.3ad",
    "mode=balance-tlb",
    "mode=balance-alb"
  ]

  validates_format_of :id, :allow_nil => false, :with => /^[a-zA-Z0-9_-]+$/
  validates_inclusion_of :bootproto, :in => ["static","dhcp", "none"]
  validates_format_of :ipaddr,
                      :allow_blank => true,
                      :with => /^#{IPADDR_REGEX}\/(#{IPADDR_REGEX}|[0-9]{1,2})$/  #(bnc#600097)

  public

  def netmask_to_cidr(netmask)
    if netmask =~ /\A\d{1,2}\Z/
      return netmask #we get already cidr
    elsif netmask =~ /\A\/\d{1,2}\Z/
      return netmask[1..-1] #we already get it with starting slash
    else
      return IPAddr.new(netmask).to_i.to_s(2).count("1")
    end
  end

  def self.cidr_to_netmask(cidr)
    return IPAddr.new('255.255.255.255').mask(cidr).to_s
  end

  def ip
    (self.ipaddr.blank?)? "" : self.ipaddr.split("/")[0]
  end

  # convert etmask to CIDR
  def cidr
    (self.ipaddr.blank?)? "" : self.ipaddr.split("/")[1]
  end

  # convert CIDR to netmask
  def netmask
    (self.cidr.blank?)? "" : IPAddr.new('255.255.255.255').mask(self.cidr).to_s
  end

  def initialize(args, id=nil)
    super args
    @id ||= id

    # use /sbin/ip to detect the ip address if bootproto == 'dhcp' (Justus Winter)
    if bootproto && bootproto.match("dhcp")
      # TODO FIXME: test whether /sbin/ip is present or catch Errno::ENOENT exception (Ruby 1.9)
      stdout, stderr, status = Open3.popen3("/sbin/ip", "-o", "-family", "inet", "addr", "show", "dev", id) do |stdin, stdout, stderr|
        match = IP_IPADDR_REGEX.match(stdout.read())
        @ipaddr = (match)? match[1] : ""
      end
    else
      @ipaddr = ipaddr || ""
    end

    if(id && id.match("br"))
        @bridge_ports = (bridge_ports.is_a? String)? bridge_ports.split(" ") : bridge_ports || [ ]
    end

    if(id && id.match("bond"))
        @bond_slaves = (bond_slaves.is_a? String)? bond_slaves.split(" ") : bond_slaves || [ ]
    end

    @bond_mode,@bond_miimon  = @bond_option.split(" ") unless bond_option.blank?

  end

  def self.find( which )
    response = YastService.Call("YaPI::NETWORK::Read")

    ifaces_h = response["interfaces"]
    Rails.logger.info "\n\n *** Response: \n  #{ifaces_h.inspect} *** \n\n"

    if which == :all
      # TODO FIXME: return Array instead of Hash for :all
      hash = Hash.new

      ifaces_h.each do |id, ifaces_h|
        hash[id] = Interface.new(ifaces_h, id)
      end

    else
      Rails.logger.debug "Requested interface: #{ifaces_h[which].inspect}"
      hash = ifaces_h[which].blank? ? nil : Interface.new(ifaces_h[which], which)
    end

    Rails.logger.info "\n\n *** Interfaces: \n  #{hash.inspect} *** \n\n"
    hash
  end


  def update
    settings = { @id=>{} }
    settings[@id]["bootproto"] = @bootproto
    settings[@id]["ipaddr"] = @ipaddr unless @ipaddr.empty?

    case self.type
      when "vlan"
        settings[@id]["vlan_id"] =  self.vlan_id || ""
        settings[@id]["vlan_etherdevice"] = self.vlan_etherdevice || ""
      when "br"
        settings[@id]["bridge"] = "yes"
        settings[@id]["bridge_ports"] = (@bridge_ports.is_a? Array) ? @bridge_ports.join(' ') : @bridge_ports
      when "bond"
        settings[@id]["bond"] = "yes"
        settings[@id]["bond_option"] = @bond_option || ""
        settings[@id]["bond_slaves"] = (@bond_slaves.is_a? Array) ? @bond_slaves.join(' ') : @bond_slaves
      when "eth"
        # save only bootproto and ip/netmask
        Rails.logger.info "ETHERNET"
      else
        Rails.logger.error "ERROR: Wrong interface type: #{self.type}"
        return false
    end

    Rails.logger.info "\n *** WRITE INTERFACE SETTING  #{settings.inspect}"

    vsettings = [ "a{sa{ss}}", settings ] # bnc#538050
    response = YastService.Call("YaPI::NETWORK::Write",{"interface" => vsettings})
    Rails.logger.info "Saved: #{response.inspect}"

    response.is_a?(Hash) && response["exit"] == "0"
  end


  def destroy
    settings = { @id=>{} }
    settings = { @id => { "delete" => "true" }}
    vsettings = [ "a{sa{ss}}", settings ]

    response = YastService.Call("YaPI::NETWORK::Write",{"interface" => vsettings})

    response.is_a?(Hash) && response["exit"] == "0"
   end

end
