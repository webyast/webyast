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
require 'shellwords'

# = Ldap model
# Proviceds access to LDAP client configuration
# Uses YaPI::LDAP for read and write operations.
class Ldap < BaseModel::Base

  attr_accessor	:server # port number is part of server string
  attr_accessor :base_dn
  attr_accessor :tls
  attr_accessor :enabled

  # Prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :server, :base_dn, :tls, :enabled
  
  CACHE_ID = "webyast_ldap"

  public

  def self.find
    Rails.cache.fetch(CACHE_ID) do
      ret = YastService.Call("YaPI::LDAP::Read")
      Rails.logger.info "Read LDAP config: #{ret.inspect}"
      ldap = Ldap.new({
        :server => ret["ldap_server"],
        :base_dn => ret["ldap_domain"],
        :tls => ret["ldap_tls"] == "1",
        :enabled => ret["start_ldap"] == "1"
      })
      ldap = {} if ldap.nil?
      ldap
    end
  end

  def save
    params = {
      "ldap_server" => [ "s", @server || ""],
      "ldap_domain" => [ "s", @base_dn || ""],
      "ldap_tls" => [ "b", @tls],
      "start_ldap" => [ "b", @enabled]
    }

    Rails.logger.debug "YaPI SEND PARAMS: '#{params.inspect}'"
    Rails.cache.delete(CACHE_ID)
    yapi_ret = YastService.Call("YaPI::LDAP::Write", params)
    Rails.logger.debug "YaPI returns: '#{yapi_ret}'"

    return true
  end


  # ask given LDAP server for available base DN
  def self.fetch(server)
    ret = { "dn" => ""}
    out = `/usr/bin/ldapsearch -x -h #{server.shellescape} -b '' -s base namingContexts | grep "namingContexts:" | cut -d" " -f 2` # RORSCAN_ITL
    ret["dn"] = out.split("\n")[0] if out
    return ret
  end
end

