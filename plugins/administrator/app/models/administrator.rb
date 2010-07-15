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
class Administrator

  attr_accessor	:aliases
  attr_reader	:password

  include Singleton

  def initialize
    @aliases	= ""
    @password	= ""
  end

  # Read mail aliases for root.
  # return value:: comma-separated string
  def read_aliases
    yapi_ret = YastService.Call("YaPI::ADMINISTRATOR::Read")
    if yapi_ret.nil?
      raise "Can't read administrator data"
    elsif yapi_ret.has_key?("aliases")
      @aliases	= yapi_ret["aliases"].join(",")
    end
    @aliases
  end

  # Sets administrator's password.
  # pw:: password (clear text)
  def save_password(pw)
    parameters  = {
      "password" => ["s", pw ]
    }
    yapi_ret = YastService.Call("YaPI::ADMINISTRATOR::Write", parameters)
    Rails.logger.debug "YaPI returns: '#{yapi_ret}'"
    return true
  end

  # Changes the list of administrator's mail aliases.
  # new_aliases:: comma-separated string
  # Use special value "NONE" for removal of current mail aliases.
  def save_aliases(new_aliases)
    new_aliases = "" if new_aliases.nil? || new_aliases == "NONE"
    if @aliases.split(",").sort == new_aliases.split(",").sort
      Rails.logger.debug "mail aliases have not been changed"
      return true
    end
    parameters	= {
      "aliases" => ["as", new_aliases.split(",")]
    }
    yapi_ret = YastService.Call("YaPI::ADMINISTRATOR::Write", parameters)
    Rails.logger.debug "YaPI returns: '#{yapi_ret}'"
    raise AdministratorError.new(yapi_ret) unless yapi_ret.empty?
    @aliases = new_aliases
  end

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]
    
    xml.administrator do
      xml.password password
      xml.aliases aliases
    end  
  end

  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash["administrator"].to_json
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
