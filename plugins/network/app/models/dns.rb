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
# = Dns model
# Provides set and gets resources from YaPI network module.
# Main goal is handle YaPI specific calls and data formats. Provides cleaned
# and well defined data.

require 'base_model/base'

class Dns < BaseModel::Base

  # the short hostname
  attr_accessor :searches
  # the domain name
  attr_accessor :nameservers

  
  
  validates_each :nameservers, :allow_nil => false do |model,attr,value|
    value.each do |nameserver|

      #TODO use better regex
      if nameserver.match(/^([0-9]{1,3}.){3}[0-9]{1,3}$/).nil?
        Rails.logger.error "NAMSERVER DOESN'T MATCH #{nameserver}"
        model.errors.add attr, :invalid
      end
    end
  end

  validates_each :searches, :allow_nil => false do |model,attr,value|
    value.each do |search|
      begin
        URI.parse search
      rescue URI::InvalidURIError => e
        Rails.logger.warn "Invalid uri: #{e.inspect}"
        Rails.logger.error "SEARCH DOESN'T MATCH #{search}"
        model.errors.add attr, :invalid
      end
    end
  end

  public

  # fills time instance with data from YaPI.
  #
  # +warn+: Doesn't take any parameters.
  def Dns.find
    YastCache.fetch(self) {
      response = YastService.Call("YaPI::NETWORK::Read") # hostname: true
      ret = Dns.new response["dns"]
    }
  end

  # Saves data from model to system via YaPI. Saves only setted data,
  # so it support partial safe (e.g. save only new timezone if rest of fields is not set).
  def update
    settings = {
      "searches" => @searches,
      "nameservers" => @nameservers,
    }
    
    vsettings = [ "a{sas}", settings ] # bnc#538050    
    Rails.logger.error "DBUS PARAMS #{settings.inspect}"
    
    YastService.Call("YaPI::NETWORK::Write",{"dns" => vsettings})
    # TODO success or not?
    YastCache.reset(self)
  end

end
