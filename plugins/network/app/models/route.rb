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
# = Routing model
# Provides set and gets resources from YaPI network module.
# Main goal is handle YaPI specific calls and data formats. Provides cleaned
# and well defined data.

require 'base'
require 'builder'

class Route < BaseModel::Base

  # default gateway
  attr_accessor :via
  validates_format_of :via, :allow_nil => true,
      :with => /^([0-9]{1,3}.){3}[0-9]{1,3}$/

	attr_accessor	:id
  validates_format_of :id, :allow_nil => false,
      :with => /^(default|[0-9.\/]+)$/

  public

  def initialize(kwargs, id = nil)
    super kwargs
    @id ||= id
  end

  # fills route instance with data from YaPI.
  #
  # +warn+: YaPI implements default only.
  def self.find which
    response = YastService.Call("YaPI::NETWORK::Read")
    routes_h = response["routes"]
    Rails.logger.debug "Routes config: #{routes_h.inspect}"

    if which == :all
      ret = []
      routes_h.each do |id, route_h|
        ret << Route.new(route_h, id)
      end
    else
      return nil if routes_h[which].nil?
      ret = Route.new(routes_h[which], which)
    end
    ret
  end

  # Saves data from model to system via YaPI. Saves only setted data,
  # so it support partial safe (e.g. save only new timezone if rest of fields is not set).
  def update
    @via="" if @via==nil
    settings = {
      @id => { 'via'=>@via },
    }
    vsettings = [ "a{sa{ss}}", settings ] # bnc#538050

    Rails.logger.error "\n *** WRITE ROUTE SETTINGS  #{vsettings.inspect}"
    exit_code = YastService.Call("YaPI::NETWORK::Write",{"route" => vsettings})

    raise RouteError.new(exit_code["error"]) if exit_code["exit"] != "0"
  end

end

require 'exceptions'
class RouteError < BackendException
  def initialize(message)
    @message = message
    super("Failed to write route setting with this error: #{@message}.")
  end

  def to_xml
    xml = Builder::XmlMarkup.new({})
    xml.instruct!

    xml.error do
      xml.type "NETWORK_ROUTE_ERROR"
      xml.description @message
      xml.output @message
    end
  end
end
