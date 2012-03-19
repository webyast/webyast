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
class SystemtimeController < ApplicationController

  #--------------------------------------------------------------------------------
  #
  # actions
  #
  #--------------------------------------------------------------------------------

  # Sets time settings. Requires write permissions for time YaPI.
  def update
    authorize! :write, Time
    root = params[:systemtime]
    if root == nil
      logger.error "Response doesn't contain systemtime key" # RORSCAN_ITL
      raise InvalidParameters.new :timezone => "Missing"
    end
    
    systemtime = Systemtime.new(root) # RORSCAN_ITL    
    systemtime.save # RORSCAN_ITL
    show
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

end

