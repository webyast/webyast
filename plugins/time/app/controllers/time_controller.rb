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

  rescue_from InvalidParameters, "::NtpError" do |error|
    respond_to do |format|
      format.html do
        flash[:error] = error.message
        redirect_to :action => :index
      end
      format.xml  { render :xml  => error.to_xml  }
      format.json { render :json => error.to_json }
    end
  end

  def index
    authorize! :read, Time
    @system_time = Systemtime.find
    respond_to do |format|
      format.html
      format.xml  { render :xml  => @system_time } # RORSCAN_ITL
      format.json { render :json => @system_time } # RORSCAN_ITL
    end
  end

  def update
    authorize! :write, Time
    system_time = Systemtime.new params[:systemtime]
    system_time.utcstatus = params[:systemtime][:utcstatus]
    raise InvalidParameters.new system_time.errors.full_messages unless system_time.valid?
    if system_time.config_ntp_sync?
      authorize! :execute, Service
      authorize! :synchronize, Ntp
      authorize! :setserver,   Ntp
    elsif system_time.config_manual?
      authorize! :execute, Service
    end
    system_time.save
    respond_to do |format|
      format.html do
        flash[:notice] = _('Time settings have been written.')
        redirect_to :action => :index
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

end
