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

# CACHING makes currently no sense cause the current time has to be
# evaluate everytime which will be also made by YaST:YAPI
# (It is not so easy as it sounds :-))

require 'base'

class Systemtime < BaseModel::Base

  # Date settings format is dd/mm/yyyy
  attr_accessor :date
  validates_format_of :date, :with => /^\d{2}\/\d{2}\/\d{4}$/, :allow_nil => true
  # time settings format is hh:mm:ss
  attr_accessor :time
  validates_format_of :time, :with => /^\d{2}:\d{2}:\d{2}$/, :allow_nil => true
  attr_accessor :timezone
  # Utc status possible values is UTCOnly, UTC and localtime see yast2-country doc
  attr_accessor   :utcstatus
  validates_inclusion_of :utcstatus, :in => ['true','false', true, false], :allow_nil => true
  attr_accessor :timezones
  attr_accessor :hwclock
  attr_accessor :region
  attr_accessor :yapi_response
  attr_accessor :timezone_details
  private       :timezone_details=, :timezones=, :hwclock=, :yapi_response

  validate :matching_with_yapi_entries

  attr_protected :timezones, :hwclock, :yapi_response

  # Creates argument for dbus call which specify what data is requested.
  TIMEZONE_KEYS = {
    "timezone"    => "true",
    "utcstatus"   => "true",
    "currenttime" => "true",
    "zones"       => "true"
  }

  def self.find
    new
  end

  def initialize params={}
    if load_yapi_response
      map_yapi_to_attributes
    else
      load_default_data
    end
    self.hwclock = File.exist? "/sbin/hwclock"
    super
  end

  def to_xml params={}
    render_attributes.to_xml params.merge :root=>:systemtime, :dasherize => false
  end

  def to_json params={}
    render_attributes.to_json params.merge :root=>:systemtime, :dasherize => false
  end

  def regions
    @regions ||= timezones.collect { |zone| zone[:region] }
  end

  def inspect
    "<##{self.class}:0x#{"%x" % (object_id.abs*2)} @region=#{region} @timezone=#{timezone} @time=#{time} " +
    "@date=#{date} @utcstatus=#{utcstatus} >"
  end

  private

  def load_default_data
    self.region   = ''
    self.timezone = ''
    self.time     = ''
    self.yapi_response = {'zones'=>[]}
  end

  def matching_with_yapi_entries
    region_valid = region_entries.present?
    if region_valid
      timezone_match = region_entries.select { |detail, zone| zone == timezone }
      case timezone_match # Hash#select returns an array in 1.8 and hash in 1.9
      when Array
        timezone_match = timezone_match.flatten
      end
      unless timezone_match.present?
        errors.add :timezone, _("Mismatch in region and timezone specification: '#{region}', '#{timezone}'")
      end
    else
      errors.add :region, _("Unknown region '#{region}'")
    end
    Rails.logger.error "Validation failed: #{errors.full_messages.join ','}" if errors.present?
  end

  def load_yapi_response
    self.yapi_response = YastService.Call "YaPI::TIME::Read", TIMEZONE_KEYS
  end

  def map_yapi_to_attributes
    timedate           = yapi_response["time"]
    self.time          = timedate[timedate.index(" - ")+3,8]
    self.date          = timedate[0..timedate.index(" - ")-1]
    self.timezones     = parse_yapi_zones
    self.timezone      = parse_yapi_timezone
    self.timezone_details = yapi_response['timezone']
    #convert date to format for datepicker
    self.date.sub!(/^(\d+)-(\d+)-(\d+)/,'\3/\2/\1')
    self.region = timezones.find {|tz| tz[:timezones].find {|zone| zone == timezone }}[:region]
    self.utcstatus =
      case yapi_response["utcstatus"]
      when "UTC"
        true
      when "localtime", 'local'
        false
      when "UTCOnly"
        true
      else
        Rails.logger.warn "Unknown key in utcstatus #{yapi_response["utcstatus"]}"
        nil
      end
    self
  end

  def parse_yapi_timezone
    yapi_timezone  = yapi_response['timezone']
    if yapi_timezone.blank? #last fallback if everything fail #bnc582166
      return "Czech Republic"
    end
    regional_zones = yapi_response['zones'].find do |zone|
      zone['entries'].find {|detail, timezone| detail == yapi_timezone }
    end
    regional_zones['entries'][yapi_timezone]
  end

  def parse_yapi_zones
    yapi_response['zones'].inject([]) do |new_zones, yapi_zones|
      new_zones.push({ :region => yapi_zones['name'], :timezones => yapi_zones['entries'].values })
      new_zones
    end
  end

  def render_attributes
    {
      :region    => region,
      :timezone  => timezone,
      :utcstatus => utcstatus,
      :hwclock   => hwclock,
      :date      => date,
      :time      => time
    }
  end

  def update_utc_status
    case utcstatus
    when true, 'true'
      'UTC'
    else
      'local'
    end
  end

  def update_date_time
    unless date.blank? || time.blank?
      date = self.date.split "/"
      "#{date[2]}-#{date[0]}-#{date[1]} - #{time}"
    end
  end

  def update_timezone
    timezone_pair = region_entries.select { |detail, zone| zone == timezone }
    case timezone_pair
    when Array
      timezone_pair.flatten.first
    when Hash
      timezone_pair.keys.first
    end
  end

  def region_entries
    region_data = yapi_response['zones'].find { |zone| zone['name'] == region }
    region_data ? region_data['entries'] : {}
  end

  def update
    if valid?
      updated_params = {}
      updated_params.merge! \
        'timezone'    => update_timezone,
        'utcstatus'   => update_utc_status,
        'currenttime' => update_date_time
      # do not specify the currenttime key if we want no change
      updated_params.delete 'currenttime' unless updated_params['currenttime']
      Rails.logger.info "Going to write new time settings with: #{updated_params.inspect}"
      begin
        saved = YastService.Call("YaPI::TIME::Write", updated_params)
      rescue Exception => e
        Rails.logger.info "Exception thrown by DBus probably timeout #{e.inspect}"
        #XXX hack to avoid dbus timeout durign moving time to future
        #FIXME use correct exception
      end
      restart_collectd
      load_yapi_response
      saved
    else
      false
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
