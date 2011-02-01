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

require 'yast_cache'

class Ntp < BaseModel::Base

  attr_accessor :actions

  public
    
    def self.find
      YastCache.fetch("ntp:find") {
        ret = Ntp.new
        ret.actions ||= {}
        ret.actions[:synchronize] = false
        ret.actions[:synchronize_utc] = true
        ret.actions[:ntp_server] = get_servers_string
        ret
      }
    end

    def update
      synchronize if @actions[:synchronize]
    end

    def self.get_servers
      Ntp.find.actions[:ntp_server]
    end

  private
    
    def self.get_servers_string
      ret = `grep "^[:space:]*NETCONFIG_NTP_STATIC_SERVERS" /etc/sysconfig/network/config | sed 's/.*="\\(.*\\)"/\\1/'` # RORSCAN_ITL
      Rails.logger.info "greped server list is #{ret}"
      ret
    end
    
    def synchronize
      @actions.delete :ntp_server if @actions[:ntp_server] == Ntp.get_servers
      ret = "OK"
      begin
        ret = YastService.Call("YaPI::NTP::Synchronize",@actions[:synchronize_utc],@actions[:ntp_server]||"")
      rescue Exception => e
        Rails.logger.info "ntp synchronization cause probably timeout #{e.inspect}"
      end
      raise NtpError.new(ret) unless ret == "OK"
    end
end

require 'exceptions'
class NtpError < BackendException
  def initialize(message)
    @message = message
    super("Ntp failed to synchronize with this error: #{@message}.")
  end

  def to_xml
    xml = Builder::XmlMarkup.new({})
    xml.instruct!

    xml.error do
      xml.type "NTP_ERROR"
      xml.description message
      xml.output @message
    end
  end
end
