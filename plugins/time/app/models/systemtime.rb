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

  attr_accessor :date
  attr_accessor :time
  attr_accessor :timezone
  attr_reader   :utcstatus
  attr_accessor :region
  attr_reader   :timezone_details, :timezones, :hwclock
  attr_reader   :ntpd_running, :ntp_available, :ntp, :ntp_server
  attr_accessor :config

  private

  attr_writer   :timezone_details, :timezones, :hwclock
  attr_writer   :ntpd_running, :ntp_available, :ntp, :ntp_server
  attr_accessor :yapi_response, :service_available

  public

  validate            :matching_with_yapi_entries
  # Date settings format is dd/mm/yyyy
  validates_format_of :date, :with => /\A\d{2}\/\d{2}\/\d{4}\Z/, :allow_nil => true
  # time settings format is hh:mm:ss
  validates_format_of :time, :with => /\A\d{2}:\d{2}:\d{2}\Z/, :allow_nil => true
  validates_inclusion_of :utcstatus, :in => [true, false], :allow_nil => true
  validates_inclusion_of :config, :in => ['manual', 'ntp_sync']

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
    load_time_config
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
    "@date=#{date} @utcstatus=#{utcstatus} @config=#{config} @ntpd_running=#{ntpd_running} @ntp_server=#{ntp_server}>"
  end

  def utcstatus= status
    @utcstatus = case status
      when 'true', true
        true
      when 'false', false, nil
        false
      else
        raise ArgumentError, "Value '#{status}' is not allowed for utc status"
    end
  end

  def region_timezones
    region_zones_available = timezones.any? { |zone| zone[:region] == region }
    if region_zones_available
      timezones.find {|zone| zone[:region] == region }[:zones].sort
    else
      timezones.first[:zones]
    end
  end

  private

  def load_default_data
    self.region   = ''
    self.timezone = ''
    self.time     = ''
    self.config = ''
    self.yapi_response = {'zones'=>[]}
  end

  def matching_with_yapi_entries
    region_valid = region_entries.present?
    if region_valid
      timezone_match = region_entries.select { |detail, zone| zone == timezone }
      # Hash#select returns an array in 1.8 and hash in 1.9
      timezone_match = timezone_match.flatten if timezone_match.is_a? Array
      unless timezone_match.present?
        errors.add :timezone, _("Mismatch in region and timezone specification: '#{region}', '#{timezone}'")
      end
    else
      errors.add :region, _("Unknown region '#{region}'")
    end
    Rails.logger.error "Validation failed: #{errors.full_messages.join ','}" if errors.present?
  end

  TIME_CONFIG = { :ntp => 'ntp_sync', :manual => 'manual' }

  def load_yapi_response
    self.yapi_response = YastService.Call "YaPI::TIME::Read", TIMEZONE_KEYS
  end

  def map_yapi_to_attributes
    self.time, self.date  = parse_yapi_timedate
    self.timezones        = parse_yapi_zones
    self.timezone         = parse_yapi_timezone
    self.region           = parse_yapi_region
    self.timezone_details = yapi_response['timezone']
    self.utcstatus = case yapi_response["utcstatus"]
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

  TIMEDATE_DELIMITER = ' - '
  TIME_SIZE = 8

  def parse_yapi_timedate
    timedate = yapi_response['time']
    delimiter_index = timedate.index TIMEDATE_DELIMITER
    time = timedate[delimiter_index + TIMEDATE_DELIMITER.size, TIME_SIZE]
    date = timedate[0..delimiter_index - 1].sub!(/^(\d+)-(\d+)-(\d+)/,'\3/\2/\1')
    [ time, date ]
  end

  def parse_yapi_timezone
    yapi_timezone  = yapi_response['timezone']
    if yapi_timezone.blank? #last fallback if everything fail #bnc582166
      return "Czech Republic"
    end
    regional_zones = yapi_response['zones'].find do |zone|
      zone['entries'].find {|detail, timezone| detail == yapi_timezone }
    end
    if regional_zones
      regional_zones['entries'][yapi_timezone]
    else
      # bnc#787113
      Rails.logger.error "Unknown timezone got from yapi/sysconfig: #{yapi_timezone}"
      "(#{_('Unknown')}) #{yapi_timezone} "
    end
  end

  def parse_yapi_zones
    yapi_response['zones'].inject([]) do |new_zones, yapi_zones|
      new_zones << { :region => yapi_zones['name'], :zones => yapi_zones['entries'].values }
    end
  end

  def parse_yapi_region
    zones = timezones.find do |tzone|
      tzone[:zones].find {|zone| zone == timezone }
    end
    if zones.present?
      zones[:region]
    else
      Rails.logger.error "Region could not have been recognized"
      _('Unknown')
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
    utcstatus ? 'UTC' : 'local'
  end

  def update_date_time
    if date.present? && time.present?
      date = self.date.split "/"
      "#{date[2]}-#{date[0]}-#{date[1]} - #{time}"
    end
  end

  def update_timezone
    timezone_pair = region_entries.select { |detail, zone| zone == timezone }
    # ruby 1.8 and 1.9
    timezone_pair.is_a?(Array) ? timezone_pair.flatten.first : timezone_pair.keys.first
  end

  def region_entries
    region_data = yapi_response['zones'].find { |zone| zone['name'] == region }
    region_data ? region_data['entries'] : {}
  end

  def update
    return false unless valid?
    updated_params = {
      'timezone'    => update_timezone,
      'utcstatus'   => update_utc_status,
      'currenttime' => update_date_time
    }
    # do not specify the currenttime key if we want no change
    updated_params.delete 'currenttime' unless updated_params['currenttime']
    set_time_config
    Rails.logger.info "Going to write new time settings with: #{updated_params.inspect}"
    begin
      YastService.Call "YaPI::TIME::Write", updated_params
    rescue Exception => e
      Rails.logger.info "Exception thrown by DBus probably timeout #{e.inspect}"
      #XXX hack to avoid dbus timeout durign moving time to future
      #FIXME use correct exception
    end
    restart_collectd
    load_yapi_response
    true
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

  def class_exists?(class_name)
    begin
      cl = Module.const_get(class_name)
      return cl.is_a?(Class)
    rescue NameError
      return false
    end
  end

  def load_time_config
    ntp_check
    if ntp_available && ntpd_running
      self.config = TIME_CONFIG[:ntp]
    else
      self.config = TIME_CONFIG[:manual]
    end
  end

  def ntp_check
    self.ntp_available     = class_exists?("Ntp")
    self.service_available = class_exists?("Service")
    if ntp_available
      `pgrep -f /usr/sbin/ntpd`
      Rails.logger.info "Checking ntpd... #{'not ' unless $?.exitstatus == 0}running."
      self.ntpd_running = $?.exitstatus == 0
      self.ntp = Ntp.find
      self.ntp_server = ntp.actions[:ntp_server]
    end
  end

  def set_time_config
    case config
    when "manual"
      if service_available && ntp_available
        service = Service.new("ntp")
        Rails.logger.info "Stopping ntpd service.."
        service.save({:execute => "stop" })
        self.ntpd_running = false
      end
    when "ntp_sync"
      if ntp_available
        ntp.actions[:synchronize] = true
        ntp.actions[:synchronize_utc] = system_time.utcstatus
        ntp.update
        Rails.logger.info "Starting ntpd service.."
        Service.new('ntp').save(:execute=>'start') if service_available
      end
    end
  end

end
