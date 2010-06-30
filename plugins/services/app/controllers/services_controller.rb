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

# = Services controller
# Provides access system and vendor sepcific services.
class ServicesController < ApplicationController
  before_filter :login_required

  # GET /services
  # Reads a list of services.
  # Requires read permission for services YaPI.
  def index
    yapi_perm_check "services.read"

    begin
	@services	= Service.find_all params
    rescue Exception => e
	render ErrorResult.error(404, 107, e.to_s) and return
    end
    respond_to do |format|
    	format.xml  { render :xml => @services.to_xml }
    	format.json { render :json => @services.to_json }
    end
  end

  # GET /services/service_name
  # Shows service status.
  # Requires read permission for services YaPI.
  def show
    yapi_perm_check "services.read"

    @service = Service.new(params[:id])

    begin
	@service.read_status(params)
    rescue Exception => e
	render ErrorResult.error(404, 108, e.to_s) and return
    end

    respond_to do |format|
	format.xml  { render :xml => @service.to_xml(:root => 'service', :dasherize => false, :indent => 2), :location => "none" }
	format.json { render :json => @service.to_json, :location => "none" }
    end
  end

  # PUT /services/1.xml
  # Execute service command (start or stop).
  # Requires execute permission for services YaPI.
  def update
    yapi_perm_check "services.execute"
    begin
      @service = Service.find params[:id]
    rescue Exception => e
      logger.debug e
      render ErrorResult.error(404, 106, "no such service") and return
    end

    ret	= @service.save(params)

    render :xml => ret
  end

end
