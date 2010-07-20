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
require 'yast_service'

# = Kerberos model
# Proviceds access to Kerberos client configuration
# Uses YaPI::KERBEROS for read and write operations.
class Kerberos < BaseModel::Base

  attr_accessor	:kdc
  attr_accessor :default_domain
  attr_accessor :default_realm
  attr_accessor :enabled

public
  def self.find
    ret = YastService.Call("YaPI::KERBEROS::Read", {})
    Rails.logger.info "Read KERBEROS config: #{ret.inspect}"
    kerberos	= Kerberos.new({
	:kdc		=> ret["kdc"],
	:default_realm	=> ret["default_realm"],
	:default_domain	=> ret["default_domain"],
	:enabled	=> ret["use_kerberos"] == "1"
    })
    kerberos	= {} if kerberos.nil?
    return kerberos
  end

  def save
    params	= {
	"kdc" 		=> [ "s", @kdc],
	"default_realm"	=> [ "s", @default_realm],
	"default_domain"=> [ "s", @default_domain],
	"use_kerberos"	=> [ "b", @enabled]
    }
    yapi_ret = YastService.Call("YaPI::KERBEROS::Write", params)
    Rails.logger.debug "YaPI returns: '#{yapi_ret}'"
    return true
  end

end
