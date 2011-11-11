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

include ApplicationHelper

require 'log'

#
# Controller that exposes log files in a RESTful
# way.
#
# GET /logs returns a description of all available logfiles
#
# GET /logs/id returns the content of a logfile with the id "id"
#

class LogsController < ApplicationController
    
  # GET /logs
  # GET /logs.xml
  #
  def index
    permission_check("org.opensuse.yast.system.status.read") # RORSCAN_ITL
    @logs = Log.find(:all)
    respond_to do |format|
      format.json { render :json => @logs.to_json }
      format.xml { render :xml => @logs.to_xml( :root => "logs", :dasherize => false ) }
    end
  end
  
  # GET /logs/system
  # GET /logs/system.xml
  #
  def show
    permission_check("org.opensuse.yast.system.status.read") # RORSCAN_ITL
    # RORSCAN_INL: User has already read permission for ALL logs here
    @logs = Log.find(params[:id])
    @logs.evaluate_content(params[:pos_begin], params[:lines])
    respond_to do |format|
      format.json { render :json => @logs.to_json }
      format.xml { render :xml => @logs.to_xml( :root => "logs", :dasherize => false ) }
    end
  end

end
