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

require 'yast_cache'

class Interface < BaseModel::Base

  IPADDR_REGEX = /([0-9]{1,3}.){3}[0-9]{1,3}/
  attr_accessor :bootproto
  validates_inclusion_of :bootproto, :in => ["static","dhcp"]
  attr_accessor :ipaddr
  # blank instead of nil as specified in restdoc, bnc#600097
  validates_format_of :ipaddr, :allow_blank => true,
      :with => /^#{IPADDR_REGEX}\/(#{IPADDR_REGEX}|[0-9]{1,2})$/
  attr_accessor	:id
  validates_format_of :id, :allow_nil => false,
      :with => /^[a-zA-Z0-9_-]+$/

  public

  def initialize(args, id=nil)
    super args
    @id ||= id
    @ipaddr ||= ""
  end

  def self.find( which )
    YastCache.fetch("interface:find") {
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
  # so it support partial safe (e.g. save only new timezone if rest of fields is not set).
  def update
    if @bootproto==""
      settings = {@id=>{}}
    else
      settings = {
        @id => {
	      "bootproto" => @bootproto,
	      "ipaddr" => @ipaddr
        }
      }
    end
    vsettings = [ "a{sa{ss}}", settings ] # bnc#538050
    YastService.Call("YaPI::NETWORK::Write",{"interface" => vsettings})
    # TODO success or not?
    YastCache.reset("interface:find")
  end

end
