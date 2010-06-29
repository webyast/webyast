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

public
  def self.find
    ret = YastService.Call("YaPI::ActiveDirectory::Read", {})
    Rails.logger.info "Read Samba config: #{ret.inspect}"
    ad	= Activedirectory.new({
	:domain		=> ret["domain"],
	:create_dirs	=> ret["mkhomedir"] == "1",
	:enabled	=> ret["winbind"] == "1"
    })
    ad	= {} if ad.nil?
    return ad
  end

  def check_membership(check_domain)
    check_domain	= "" if check_domain.nil?
    ret = YastService.Call("YaPI::ActiveDirectory::Read", { "check_membership"	=> ["s", check_domain]})
    Rails.logger.info "Is member of domain #{check_domain}: #{ret.inspect}"
    return ret
  end

  def save
    # FIXME cache the information from check_membership (ADS, realm) and use them for join... ?

    params	= {
	"domain"	=> [ "s", @domain ],
	"winbind"	=> [ "b", @enabled ],
	"mkhomedir"	=> [ "b", @create_dirs ]
    }

    # if credentials not present, call check_membership:
    # - if not member, ask for credentials (exception), otherwise write settings
    if @administrator.nil?
	ret	= check_membership(@domain)
	raise ActivedirectoryError.new("not_member","") unless ret["result"]
    else
	# join args are present
	params["administrator"]	= [ "s", @administrator]
	params["password"]	= [ "s", @password ] unless @password.nil?
	params["machine"]	= [ "s", @machine ] unless @machine.nil?
    end

    yapi_ret = YastService.Call("YaPI::ActiveDirectory::Write", params)
    Rails.logger.debug "Write YaPI returns: '#{yapi_ret}'"
    if yapi_ret["join_error"]
	raise ActivedirectoryError.new("not_joined",yapi_ret["join_error"])
    elsif yapi_ret["write_error"]
	raise ActivedirectoryError.new("write_failed","")
    end
    return true
  end

end

require 'exceptions'
class ActivedirectoryError < BackendException

  def initialize(id,message)
    @id		= id
    @message	= message
  end

  def to_xml
    xml = Builder::XmlMarkup.new({})
    xml.instruct!

    xml.error do
      xml.type "ADMINISTRATOR_ERROR"
      xml.id @id
      xml.message @message
    end
  end
end
