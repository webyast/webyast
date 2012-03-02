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
# = Hostname model
# Provides set and gets resources from YaPI network module.
# Main goal is handle YaPI specific calls and data formats. Provides cleaned
# and well defined data.

require 'base'
require "yast/config_file"

# Network.find return the same values as Hostname.find, Routes.find, Dns.find and Interfaces.find 
# but with only one YaPI call

class Network < BaseModel::Base
  def self.find

    YastCache.fetch(self) {
      @response = YastService.Call("YaPI::NETWORK::Read") # hostname: true
    }

    ifaces = Hash.new
    @response["interfaces"].each{|id, iface| ifaces[id] = Interface.new(iface, id)}

    route = Route.new(@response["routes"]["default"], "default")
    dns = Dns.new(@response["dns"])
    hostname = Hostname.new(@response["hostname"])

    return {"interfaces" => ifaces, "routes" => route, "dns" => dns, "hostname" => hostname}
  end
end
