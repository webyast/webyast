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

#require 'yast/service_resource'
require 'services_helper'

class ServicesController < ApplicationController
#  before_filter :login_required
  layout 'main'

  private

  # Initialize GetText and Content-Type.
  FastGettext.add_text_domain 'webyast-services', :path => 'locale'

  public

  def show_status
    authorize! :read, Service
    
    service = Service.new(params[:id])
    @response = service.read_status({ "custom" => params[:custom]})

    #Rails.logger.info @response.to_yaml

    render(
      :partial =>'status',
      :locals	=> { :status => @response.status, :enabled => @response.enabled, :custom => @response.custom },
      :params => params
    )
  end

  # GET /services
  # GET /services.xml
  def index
    authorize! :read, Service
    @exec_permission = can? :execute, Service
    
    @services = []
    all_services	= []
    all_services	= Service.find(:all, { :read_status => 1 })
    
    # there's no sense in showing these in UI (bnc#587885)
    killer_services	= [ "webyast", "dbus", "network", "lighttpd" ]

    all_services.each do |s|
      # only leave dependent services that are shown in the UI
      s.required_for_start.reject! { |rs| killer_services.include? rs }
      s.required_for_stop.reject! { |rs| killer_services.include? rs }
      @services.push s unless killer_services.include? s.name
    end
    
    respond_to do |format|
      format.html
      format.xml  { render :xml => @services.to_xml }
      format.json { render :json => @services.to_json }
    end
    
  end

  # PUT /services/1.xml
  def execute
    authorize! :execute, Service
    
    args = { :execute => params[:id], :custom => params[:custom] }
    service = Service.new(params["service_id"]) 
    ret = service.save(args)
    
    #Rails.logger.debug "*** YaPI RETURNS \n #{ret} \n"
    #Rails.logger.debug "returns #{ret.inspect}"
    
    @result_string = ""
    @result_string << ret["stdout"] if ret["stdout"]
    @result_string << ret["stderr"] if ret["stderr"]
    @error_string = ret["exit"].to_s

    @error_string = case @error_string
       when "0" then _("success")
       when "1" then _("unspecified error")
       when "2" then _("invalid or excess argument(s)")
       when "3" then _("unimplemented feature")
       when "4" then _("user had insufficient privilege")
       when "5" then _("program is not installed")
       when "6" then _("program is not configured")
       when "7" then _("program is not running")
    end

    #Rails.logger.error "Render partial RESULT with PARAMS #{params.inspect}"
    render(:partial =>'result')
  end

  # GET /services/1.xml
  # REST API
  def show
    authorize! :read, Service

    @service = Service.new(params[:id])
    @service.read_status(params)
    
    respond_to do |format|
      format.xml  { render :xml => @service.to_xml(:root => 'service', :dasherize => false, :indent => 2), :location => "none" }
      format.json { render :json => @service.to_json, :location => "none" }
    end
  end
  
  # PUT /services/1.xml
  # Execute service command (start or stop).
  # Requires execute permission for services YaPI.
  def update
    authorize :execute, Service
    @service = Service.find params[:id]
    ret = @service.save(params)
    render :xml => ret
  end

end
