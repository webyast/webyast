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
require "open3"

class Interface < BaseModel::Base

  IPADDR_REGEX = /([0-9]{1,3}.){3}[0-9]{1,3}/
  IP_IPADDR_REGEX = /inet (#{IPADDR_REGEX})/

  attr_accessor :id, :bootproto, :ipaddr
  attr_accessor :vlan_etherdevice, :vlan_id

  validates_format_of :id, :allow_nil => false, :with => /^[a-zA-Z0-9_-]+$/
  validates_inclusion_of :bootproto, :in => ["static","dhcp"]
  validates_format_of :ipaddr, :allow_blank => true, :with => /^#{IPADDR_REGEX}\/(#{IPADDR_REGEX}|[0-9]{1,2})$/  #(bnc#600097)

  public

  def initialize(args, id=nil)
    super args
    @id ||= id

    # Use /sbin/ip to detect the ip address if bootproto == 'dhcp' (Justus Winter)
    if bootproto == "dhcp"
      stdout, stderr, status = Open3.popen3("/sbin/ip", "-o", "-family", "inet", "addr", "show", "dev", id) do |stdin, stdout, stderr|
        match = IP_IPADDR_REGEX.match(stdout.read())
        @ipaddr = (match)? match[1] : ""
      end
    else
      @ipaddr = ipaddr
    end

  end

  def self.find( which )
    YastCache.fetch(self, which) {
      response = YastService.Call("YaPI::NETWORK::Read")
      ifaces_h = response["interfaces"]

      if which == :all
        ret = Hash.new
        ifaces_h.each do |id, ifaces_h|
          ret[id] = Interface.new(ifaces_h, id)
        end
      else
        ret = Interface.new(ifaces_h[which], which)
      end
      ret
    }
  end

  # Saves data from model to system via YaPI. Saves only setted data,
  # so it support partial safe (e.g. save only new timezone if rest of fields is not set). ????????
  def update
#    @id = Hash.new
#    interface = {}
#    interface["bootproto"] = @bootproto if @bootproto
#    interface["ipaddr"] = @ipaddr if @ipaddr
#    interface["vlan_etherdevice"] = @vlan_etherdevice if @vlan_etherdevice
#    interface["vlan_id"] = @vlan_id if @vlan_id

#    settings = { @id => interface }


    if @bootproto.empty?
      settings = { @id=>{} }
    else
      @vlan_id = @vlan_id || ""
      @vlan_etherdevice = @vlan_etherdevice || ""

      settings = {
        @id => {
        "bootproto" => @bootproto,
        "ipaddr" => @ipaddr,
        "vlan_id" => @vlan_id,
        "vlan_etherdevice" => @vlan_etherdevice,
        }
      }
    end

    Rails.logger.error "********** SETTINGS BEFORE SAVE #{settings.inspect}"
    vsettings = [ "a{sa{ss}}", settings ] # bnc#538050
    response = YastService.Call("YaPI::NETWORK::Write",{"interface" => vsettings})

    Rails.logger.error "********** RESPONSE FROM YAPI?? #{response.inspect}"

    # TODO success or not?
    YastCache.reset(self,@id)
  end

end
