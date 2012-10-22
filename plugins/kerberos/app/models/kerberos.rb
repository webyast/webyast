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
require 'base'

# = Kerberos model
# Proviceds access to Kerberos client configuration
# Uses YaPI::KERBEROS for read and write operations.
class Kerberos < BaseModel::Base

  attr_accessor	:kdc
  attr_accessor :default_domain
  attr_accessor :default_realm
  attr_accessor :enabled
  attr_accessor :dns_used

  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :kdc, :default_domain, :default_realm, :enabled, :dns_used
  
  CACHE_ID = "webyast_kerberos"

  public

  def self.find
    Rails.cache.fetch(CACHE_ID) do
      ret = YastService.Call("YaPI::KERBEROS::Read", {})
      Rails.logger.info "Read KERBEROS config: #{ret.inspect}"
      kerberos = Kerberos.new({
        :kdc => ret["kdc"],
        :default_realm => ret["default_realm"],
        :default_domain => ret["default_domain"],
        :enabled => ret["use_kerberos"] == "1",
        :dns_used => ret["dns_used"] == "1"
      })
      kerberos = {} if kerberos.nil?
      kerberos
    end
  end

  def save
    params = {}
    params["kdc"] = [ "s", @kdc] unless @kdc.nil?
    params["default_realm"] = [ "s", @default_realm] unless @default_realm.nil?
    params["default_domain"] = [ "s", @default_domain] unless @default_domain.nil?
    params["use_kerberos"] = [ "b", @enabled] unless @enabled.nil?
    params["dns_used"] = [ "b", @dns_used] unless @dns_used.nil?

    Rails.cache.delete(CACHE_ID)
    yapi_ret = YastService.Call("YaPI::KERBEROS::Write", params)
    Rails.logger.debug "YaPI returns: '#{yapi_ret}'"

    return true
  end

end
