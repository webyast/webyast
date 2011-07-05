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

class Firewall < BaseModel::Base

  attr_accessor :use_firewall, :fw_services

  def self.find
    YastCache.fetch("firewall:find") {
      firewall = Firewall.new YastService.Call("YaPI::FIREWALL::Read")
      return firewall
    }
  end

  def save
    result = {"saved_ok" => true}
    fw_save_data = {'use_firewall' => @use_firewall, 'fw_services' => @fw_services.collect {|h| h.delete "name"; h} }
    result = YastService.Call("YaPI::FIREWALL::Write", Firewall.toVariantASV(fw_save_data) )
    YastCache.reset("firewall:find")
    raise FirewallException.new(result["error"]) unless result["saved_ok"]
  end

  def self.toVariant(value)
    if value.is_a? TrueClass
      ["b",true]
    elsif value.is_a? FalseClass
      ["b",false]
    elsif value.is_a? String
      ["s",value]
    elsif value.is_a? Fixnum
      ["i",value]
    elsif value.is_a? Float
      ["d",value]
    elsif value.is_a? Hash
      ["a{sv}", value.to_a.collect {|kv| [ (kv[0].to_s), toVariant(kv[1])] } ]
    elsif value.is_a? Array
      ["av", value.collect {|v| toVariant v}]
    elsif value.nil?
      Rails.logger.error "WARNING: Firewall service description is missing"
    else
      raise "Unknown variant type! #{value}"
    end
  end

  def self.toVariantASV(value)
    result = value.clone
    result.each {|k,v| result[k] = toVariant(v) }
    result
  end
end

require 'exceptions'

# Exception, which signalizes, that some functionality of backend was requested
# without accepting the EULA first.
class FirewallException < BackendException
  def initialize(error_string = '')
    super "Firewall configuration saving error."
    @error_string = error_string
  end

  def to_xml(options={})
    no_arg_to_xml(options,"GENERAL", "Firewall error: '#{@error_string}'.")
  end
end
