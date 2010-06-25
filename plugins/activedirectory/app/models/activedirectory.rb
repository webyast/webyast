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

# = Active Directory model
# Proviceds access to Active Directory client configuration
# Uses YaPI::ActiveDirectory for read and write operations.
class Activedirectory < BaseModel::Base

  attr_accessor	:domain
  attr_accessor :enabled
  attr_accessor :create_dirs
  attr_accessor :joined

  # used only for joining:
  attr_accessor :administrator
  attr_accessor :password
  attr_accessor :machine

public
  def self.find
    ret = YastService.Call("YaPI::ActiveDirectory::Read")
    Rails.logger.info "Read Samba config: #{ret.inspect}"
    ad	= Activedirectory.new({
	:domain		=> ret["workgroup"],
	:create_dirs	=> ret["mkhomedir"] == "1",
	:enabled	=> ret["winbind"] == "1"
    })
    ad	= {} if ad.nil?
    return ad
  end

  def save
    params	= {}
    yapi_ret = YastService.Call("YaPI::ActiveDirectory::Write", params)
    Rails.logger.debug "YaPI returns: '#{yapi_ret}'"
    return true
  end

end
