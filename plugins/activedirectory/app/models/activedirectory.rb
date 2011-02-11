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

  # used only for joining:
  attr_accessor :administrator
  attr_accessor :password
  attr_accessor :machine

  # boolean value: if we should leave domain
  attr_accessor :leave

public
  def self.find
    YastCache.fetch("activedirectory:find") {
      ret = YastService.Call("YaPI::ActiveDirectory::Read", {})
      Rails.logger.info "Read Samba config: #{ret.inspect}"
      ad = Activedirectory.new({
	:domain		=> ret["domain"],
	:create_dirs	=> ret["mkhomedir"] == "1",
	:enabled	=> ret["winbind"] == "1"
      })
      leave = false
      ad = {} if ad.nil?
      ad
    }
  end

  def check_membership(check_domain)
    check_domain	= "" if check_domain.nil?
    ret = YastService.Call("YaPI::ActiveDirectory::Read", { "check_membership"	=> ["s", check_domain]})
    Rails.logger.info "Is member of domain #{check_domain}: #{ret.inspect}"
    return ret
  end

  def save
    params	= {
	"domain"	=> [ "s", @domain ],
	"winbind"	=> [ "b", @enabled ],
	"mkhomedir"	=> [ "b", @create_dirs ]
    }
    # only pass if @leave was intentionally set to true
    params["leave"]	=  [ "b", @leave ] if @leave

    if !@enabled
	Rails.logger.debug "disabling"
    # if credentials not present, call check_membership:
    # - if not member, ask for credentials (exception), otherwise write settings
    elsif @administrator.nil?
	ret	= check_membership(@domain)
	Rails.cache.write('activedirectory:domain', @domain)
	Rails.cache.write('activedirectory:ads', ret["ads"]) if ret["ads"]
	Rails.cache.write('activedirectory:realm', ret["realm"]) if ret["realm"]
	Rails.cache.write('activedirectory:workgroup', ret["workgroup"]) if ret["workgroup"]
	raise ActivedirectoryError.new("not_member","") unless ret["result"]
    else
	# join args are present
	params["administrator"]	= [ "s", @administrator]
	params["password"]	= [ "s", @password ] unless @password.nil?
	params["machine"]	= [ "s", @machine ] unless @machine.nil?
    end

    domain_cache	= Rails.cache.read('activedirectory:domain') || ""
    if (domain_cache == @domain)
	ads		= Rails.cache.read('activedirectory:ads') || ""
	realm		= Rails.cache.read('activedirectory:realm') || ""
	workgroup	= Rails.cache.read('activedirectory:workgroup') || ""
	params["ads"]	= [ "s", ads ] unless ads.nil? || ads.empty?
	params["realm"]	= [ "s", realm ] unless realm.empty?
	params["workgroup"]	= [ "s", workgroup ] unless workgroup.empty?
    end

    yapi_ret = YastService.Call("YaPI::ActiveDirectory::Write", params)
    Rails.logger.debug "Write YaPI returns: '#{yapi_ret}'"
    if yapi_ret["join_error"]
	raise ActivedirectoryError.new("join_error",yapi_ret["join_error"])
    elsif yapi_ret["leave_error"]
	raise ActivedirectoryError.new("leave_error",yapi_ret["leave_error"])
    elsif yapi_ret["write_error"]
	raise ActivedirectoryError.new("write_error","")
    end

    Rails.cache.write('activedirectory:domain', "")
    Rails.cache.write('activedirectory:ads', "")
    Rails.cache.write('activedirectory:realm', "")
    Rails.cache.write('activedirectory:workgroup', "")

    YastCache.reset("activedirectory:find")
    return true
  end

end

require 'exceptions'
class ActivedirectoryError < BackendException
  attr_reader :id

  def initialize(id,message)
    @id		= id
    @message	= message
  end

  def to_xml
    xml = Builder::XmlMarkup.new({})
    xml.instruct!

    xml.error do
      xml.type "ACTIVEDIRECTORY_ERROR"
      xml.id @id
      xml.message @message
    end
  end
end
