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

# = Systemtime model
# Provides set and gets resources from YaPI time module.
# Main goal is handle YaPI specific calls and data formats. Provides cleaned
# and well defined data.
class Systemtime < BaseModel::Base

  # Date settings format is dd/mm/yyyy
  attr_accessor :date
  validates_format_of :date, :with => /^\d{2}\/\d{2}\/\d{4}$/, :allow_nil => true
  # time settings format is hh:mm:ss
  attr_accessor :time
  validates_format_of :time, :with => /^\d{2}:\d{2}:\d{2}$/, :allow_nil => true
  # Current timezone as id
  attr_accessor :timezone
  # Utc status possible values is UTCOnly, UTC and localtime see yast2-country doc
  attr_accessor :utcstatus
  validates_inclusion_of :utcstatus, :in => [true,false], :allow_nil => true
  attr_accessor :timezones
  # do not massload timezones, as it is read-only
  attr_protected :timezones

  after_save :restart_collectd

  private

  # Creates argument for dbus call which specify what data is requested.
  # Available timezones is cached so request it only if it is necessary.
  # return:: hash with requested keys
  def self.create_read_question #:doc:
    ret = {
      "timezone" => "true",
      "utcstatus" => "true",
      "currenttime" => "true",
      "zones"  => "true"
    }
    return ret
  end

  public

  # Parses response from dbus YaPI call
  # response:: response from dbus
  def parse_response(response) #:doc:
    timedate = response["time"]
    @time = timedate[timedate.index(" - ")+3,8]
    @date = timedate[0..timedate.index(" - ")-1]
    #convert date to format for datepicker
    @date.sub!(/^(\d+)-(\d+)-(\d+)/,'\3/\2/\1')
    @utcstatus = 
    case response["utcstatus"]
      when "UTC" then true
      when "local" then false
      when "UTCOnly" then nil
      else 
        Rails.logger.warn "Unknown key in utcstatus #{response["utcstatus"]}"
        nil #set nill, maybe exception???
    end
    @timezone = response["timezone"]
    @timezones = response["zones"]
    @timezones.each do |zone|
      zone["entries"] = zone["entries"].collect {|k,v| { "id" => k, "name" => v } } #hack to avoid colission in xml tag
    end
  end

  # fills time instance with data from YaPI.
  #
  # +warn+: Doesn't take any parameters.
  def self.find
    ret = Systemtime.new()
    ret.parse_response YastService.Call("YaPI::TIME::Read",create_read_question)
    ret.timezone = "Europe/Prague" if ret.timezone.blank? #last fallback if everything fail #bnc582166
    return ret
  end

  # Saves data from model to system via YaPI. Saves only setted data,
  # so it support partial safe (e.g. save only new timezone if rest of fields is not set).
  def update
    settings = {}
    RAILS_DEFAULT_LOGGER.info "called write with #{settings.inspect}"
    settings["timezone"] = @timezone unless @timezone.blank?
    unless @utcstatus.nil?
      settings["utcstatus"] = @utcstatus ? "UTC" : "localtime"
    end
    unless @date.blank? || @time.blank?
      date = @date.split("/")
      datetime = "#{date[2]}-#{date[0]}-#{date[1]} - "+@time
      settings["currenttime"] = datetime
    end

    RAILS_DEFAULT_LOGGER.info "called write with #{settings.inspect}"

    begin
      YastService.Call("YaPI::TIME::Write",settings)
    rescue Exception => e
      Rails.logger.info "Exception thrown by DBus probably timeout #{e.inspect}"
      #XXX hack to avoid dbus timeout durign moving time to future
      #FIXME use correct exception
    end
  end

  def restart_collectd
    #restart collectd as moving in time confuse status module (bnc#557929)
    begin
      ret = YastService.Call("YaPI::SERVICES::Execute",{
            "name" => ["s","collectd"],
            "action" => ["s","restart"]
          })
      Rails.logger.info "Calling restart of collectd with result: #{ret.inspect}"
    rescue Exception => e
      Rails.logger.warn "Exception thrown by DBus while restarting collectd #{e.inspect}"
      #restarting collectd is optional, so it should not do anything
    end
    true
  end
end
