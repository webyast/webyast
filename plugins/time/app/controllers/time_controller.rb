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

require 'systemtime' # RORSCAN_ITL

# = Systemtime controller
# Provides access to time settings for authentificated users.
# Main goal is checking permissions.
class TimeController < ApplicationController

  private

  attr_accessor :ntp, :ntp_available, :service_available

  public

  before_filter :init

  rescue_from InvalidParameters, "::NtpError" do |error|
    respond_to do |format|
      format.html do
        flash[:error] = error.message
        redirect_to :index
      end
      format.xml  { render :xml  => error.to_xml  }
      format.json { render :json => error.to_json }
    end
  end

  def index
    authorize! :read, Time
    if ntp_available
      self.ntp = Ntp.find
      `pgrep -f /usr/sbin/ntpd`
      Rails.logger.info "ntpd is running: #{$?.exitstatus == 0}"
    end
    @system_time = Systemtime.find
    respond_to do |format|
      format.html
      format.xml  { render :xml  => @system_time } # RORSCAN_ITL
      format.json { render :json => @system_time } # RORSCAN_ITL
    end
  end

  def update
    authorize! :write, Time
    raise InvalidParameters.new _("Missing parameter 'systemtime'") unless params[:systemtime]
    system_time = Systemtime.new params[:systemtime]
    raise InvalidParameters.new _(system_time.errors.full_messages.join(', ')) unless system_time.valid?

    system_time.region    = params[:systemtime][:region]
    system_time.timezone  = params[:systemtime][:timezone]
    system_time.utcstatus = params[:systemtime][:utcstatus]
    system_time.time      = nil # set time below
    system_time.date      = nil # set date below
    system_time.save # save the timezone stuff before proceeding to time settings

    if params[:systemtime][:config]
      case params[:systemtime][:config]
      when "manual"
        if service_available && ntp_available
          authorize! :execute, Service
          service = Service.new("ntp")
          service.save({:execute => "stop" })
        end
        system_time.time = params[:systemtime][:time]
        system_time.date = params[:systemtime][:date]
      when "ntp_sync"
        if ntp_available
          authorize! :synchronize, Ntp
          authorize! :setserver,   Ntp
          ntp = Ntp.find
          ntp.actions[:synchronize] = true
          ntp.actions[:synchronize_utc] = system_time.utcstatus
          ntp.actions[:ntp_server] = params[:ntp_server]
          ntp.update
          Service.new('ntp').save(:execute=>'start') if service_available
        end
      end
      system_time.save
    end

    respond_to do |format|
      format.html do
        flash[:notice] = _('Time settings have been written.')
        redirect_to :action => 'index'
      end
      format.xml  { render :xml  => system_time }
      format.json { render :json => system_time }
    end
  end

  alias_method :create, :update

  def timezones
    authorize! :read, Time
    system_time = Systemtime.find  # RORSCAN_ITL
    respond_to do |format|
      format.xml  { render :xml  => system_time.timezones.to_xml( :root=>:timezones, :dasherize => false) }
      format.json { render :json => system_time.timezones.to_json(:root=>:timezones, :dasherize => false) }
    end
  end

  private

  def class_exists?(class_name)
    begin
      cl = Module.const_get(class_name)
      return cl.is_a?(Class)
    rescue NameError
      return false
    end
  end

  def init
    self.ntp_available     = class_exists?("Ntp")
    self.service_available = class_exists?("Service")
  end


end
