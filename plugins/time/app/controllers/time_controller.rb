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

  before_filter :init

  rescue_from InvalidParameters do |error|
    respond_to do |format|
      format.html do
        flash[:error] = error.message
        redirect_to :back
      end
      format.xml { render :xml => error.to_xml }
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
    @ntp_available     = class_exists?("Ntp")
    @service_available = class_exists?("Service")
  end


public

  def index
    authorize! :read, Time

    @ntp = @ntp_available ? Ntp.find : nil
    Rails.logger.debug "NTP: #{@ntp.inspect}"

    if @ntp_available
      `pgrep -f /usr/sbin/ntpd`
      @ntpd_running = $?.exitstatus == 0
      Rails.logger.info "ntpd is running: #{@ntpd_running}"
    end

    @stime = Systemtime.find
    @stime.load_timezone params if params[:timezone] #do not reset timezone if ntp fail (bnc#600370)

    respond_to do |format|
      format.html
      format.xml { render  :xml => @stime.to_xml( :dasherize => false ) } # RORSCAN_ITL
      format.json { render :json => @stime.to_json( :dasherize => false ) } # RORSCAN_ITL
    end
  end


  # Sets time settings. Requires write permissions for time YaPI.
  def update
    authorize! :write, Time
    if @ntp_available
      authorize! :execute, Service
      authorize! :synchronize, Ntp
      authorize! :setserver, Ntp
    end

    time_params = params[:systemtime]
    raise InvalidParameters.new :time => "missing parameter 'systemtime'" unless time_params

    t = Systemtime.find
    t.load_timezone time_params.reject {|param, _| [:time, :date].member? param }
    error = nil
    case time_params[:config]
    when "manual"
      if @service_available
        service = Service.new("ntp")
        service.save({:execute => "stop" })
      else
        logger.error "Service module is not installed -> cannot stop ntp"
      end
      t.load_time time_params
    when "ntp_sync"
      #start ntp service
      if @ntp_available
        ntp = Ntp.find
        ntp.actions[:synchronize] = true
        ntp.actions[:synchronize_utc] = t.utcstatus
        ntp.actions[:ntp_server] = time_params[:ntp_server]
        begin
          ntp.update
        rescue Exception => error
          logger.error "ntp.update returns ERROR: #{error.inspect}"
        end
        if @service_available
          service = Service.new("ntp")
          service.save({:execute => "start" })
        else
          logger.error "Service module is not installed -> cannot start ntp"
        end
      end
    when "none"
    else
      logger.error "Unknown value for time config: #{time_params[:config]}"
    end

    t.save unless error
    respond_to do |format|
      format.html { if error
                      flash[:error] = error.message
                      redirect_to :action => "index" and return
                    else
                      flash[:notice] = _('Time settings have been written.')
                      redirect_to :action => 'index'
                    end
                  }
      format.xml  { if error
                      render ErrorResult.error(404, 2, "Time setting error:'"+error.message+"'") and return
                    else
                      show and return
                    end
                  }
      format.json { unless result.blank?
                      render ErrorResult.error(404, 2, "Time setting error:'"+error.message+"'") and return
                    else
                      show and return
                    end
                  }
    end
  end

  # See update
  def create
    update
  end

  # Shows time settings. Requires read permission for time YaPI.
  def show
    authorize! :read, Time
    systemtime = Systemtime.find # RORSCAN_ITL

    respond_to do |format|
      format.xml { render  :xml => systemtime.to_xml( :dasherize => false ) } # RORSCAN_ITL
      format.json { render :json => systemtime.to_json( :dasherize => false ) } # RORSCAN_ITL
    end

  end

  #AJAX function that renders new timezones for selected region. Expected
  # initialized values from index call.
  def timezones_for_region
    #FIXME do not use AJAX use java script instead as reload of data is not needed
    # since while calling this function there is different instance of the class
    # than when calling index, @@timezones were empty; reinitialize them
    # possible FIXME: how does it increase the amount of data transferred?
    authorize! :read, Time
    systemtime = Systemtime.find  # RORSCAN_ITL

    timezones = systemtime.timezones # RORSCAN_ITL

    region = timezones.find { |r| r["name"] == params[:value] }
    return false unless region
    render(:partial => 'timezones', :locals => {:region => region, :default => region["central"], :disabled => ! params[:disabled]=="true"})
  end

end
