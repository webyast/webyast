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
require 'singleton'
require 'yast_service'

# = Administrator model
# Proviceds access to system administrator.
# Uses YaPI::ADMINISTRATOR for read and write operations.
class Administrator < BaseModel::Base

  attr_accessor	:aliases
  attr_reader	:password

  def initialize(params)
    super params
    @password	||= ""
  end

  # Read mail aliases for root.
  # return value:: comma-separated string
  def self.find
    YastCache.fetch("administrator:find") {
      yapi_ret = YastService.Call("YaPI::ADMINISTRATOR::Read")
      if yapi_ret.nil?
        raise "Can't read administrator data"
      elsif yapi_ret.has_key?("aliases")
        yapi_ret["aliases"]	= yapi_ret["aliases"].join(",")
      end
      Administrator.new yapi_ret
    }
  end

  # Changes the list of administrator's mail aliases.
  # new_aliases:: comma-separated string
  # Use special value "NONE" for removal of current mail aliases.
  def update
    @aliases = "" if @aliases == "NONE"
    parameters	= {}
    parameters["aliases"] = ["as", @aliases.split(",")] unless @aliases.nil?
    parameters["password"] = ["s", @password ] unless @password.blank?
    
    yapi_ret = YastService.Call("YaPI::ADMINISTRATOR::Write", parameters)
    Rails.logger.debug "YaPI returns: '#{yapi_ret}'"
    YastCache.reset("administrator:find")
    raise AdministratorError.new(yapi_ret) unless yapi_ret.empty?
  end
end

require 'exceptions'
class AdministratorError < BackendException

  def initialize(message)
    @message = message
    super("Administrator setup failed with this error: #{@message}.")
  end

  def to_xml
    xml = Builder::XmlMarkup.new({})
    xml.instruct!

    xml.error do
      xml.type "ADMINISTRATOR_ERROR"
      xml.description message
      xml.output @message
    end
  end
end
