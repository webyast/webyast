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
# = Hostname model
# Provides set and gets resources from YaPI network module.
# Main goal is handle YaPI specific calls and data formats. Provides cleaned
# and well defined data.

require 'base'

class Hostname < BaseModel::Base
  attr_accessor :name
  attr_accessor :domain
  attr_accessor :dhcp_hostname
  attr_accessor :dhcp_hostname_enabled

  validates_uri :name, :domain, :allow_nil => true

  public

  def initialize(args)
    super
    @dhcp_hostname_enabled = !!dhcp_hostname
  end


  # fills time instance with data from YaPI.
  # +warn+: Doesn't take any parameters.
  def self.find
    response = YastService.Call("YaPI::NETWORK::Read") # hostname: true
    Rails.logger.error "HOSTNAME NETWORK RESPONSE #{response.inspect}"
    Hostname.new response["hostname"]
  end

  # Saves data from model to system via YaPI. Saves only setted data,
  # so it support partial safe (e.g. save only new timezone if rest of fields is not set).
  def update
    settings = {}
    settings["name"] = @name if @name
    settings["domain"] = @domain if @domain
    settings["dhcp_hostname"] = @dhcp_hostname if @dhcp_hostname
    return if settings.empty?

    vsettings = [ "a{ss}", settings ] # bnc#538050

    Rails.logger.error "\n *** WRITE HOSTNAME SETTINGS #{vsettings.inspect}"
    exit_code = YastService.Call("YaPI::NETWORK::Write",{"hostname" => vsettings})

    raise HostnameError.new(exit_code["error"]) if exit_code["exit"] != "0"
  end

end

require 'exceptions'
class HostnameError < BackendException
  def initialize(message)
    @message = message
    super("Failed to write dns setting with this error: #{@message}.")
  end

  def to_xml
    xml = Builder::XmlMarkup.new({})
    xml.instruct!

    xml.error do
      xml.type "NETWORK_HOSTNAME_ERROR"
      xml.description @message
      xml.output @message
    end
  end
end
