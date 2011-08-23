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
# = Active Directory controller
# Provides access to configuration of Active Directory

#require 'client_exception'

class ActivedirectoryController < ApplicationController
  
  before_filter :login_required
  #before_filter :set_perm
  layout 'main'

  # Initialize GetText and Content-Type.
  init_gettext 'yast_webclient_activedirectory'
  
  def index
    yapi_perm_check "activedirectory.read"
    
    @poll_for_updates = true
    @write_permission = yapi_perm_granted?("activedirectory.write")
    
    begin
      @activedirectory = Activedirectory.find
      Rails.logger.debug "ad: #{@activedirectory.inspect}"
      
    rescue ActiveResource::ResourceNotFound => e
      flash[:error] = _("Cannot read Active Directory client configuraton.")
      @activedirectory  = nil
      @write_permission  = {}
      render :index and return
    end

    logger.debug "permissions: #{@write_permission.inspect}"
    return unless @activedirectory
  end

  # PUT action
  # Write AD client configuration
  def update
    @poll_for_updates = false
    @write_permission = yapi_perm_granted?("activedirectory.write")
    yapi_perm_check "activedirectory.write"
    
#    Rails.logger.error "REQUEST ************"
#    Rails.logger.error request.instance_variable_names.inspect
#    Rails.logger.error "END REQUEST ************"
#    
#    
##    ["@parameters", "@request_method", "@env"]
#    
#    Rails.logger.error "REQUEST DETAILS ************"
#    Rails.logger.error "\n#{request.parameters.to_xml}\n"
#    Rails.logger.error "\n#{request.request_method.instance_variable_names}\n"
#    Rails.logger.error "\n#{request.env.to_xml}\n"
#    
#    Rails.logger.error "END REQUEST DETAILS ************"
    
    
    if request.format.html? #HTML
      Rails.logger.debug "HTML CALL"
      
      begin
        params[:activedirectory][:enabled] = params[:activedirectory][:enabled] == "true"
        #@activedirectory = Activedirectory.new(params[:activedirectory])
        
        args = params["activedirectory"]
        args = {} if args.nil?
        @activedirectory = Activedirectory.find
        @activedirectory.load args
        @activedirectory.save
        
        flash[:message] = _("Active Directory client configuraton successfully written.")
        redirect_success
        
      rescue ActivedirectoryError => e
        # credentials required for joining the domain
        if e.id == "not_member"
          flash[:mesage] = _("Machine is not member of given domain. Enter the credentials needed for join.")
          @activedirectory.administrator = ""
          @activedirectory.password = ""
          @activedirectory.machine = ""
          render :index and return
          
        elsif e.id == "join_error"
          flash[:error] = _("Error while joining Active Directory domain: %s") % e.message
          render :index and return
          
        elsif e.id == "leave_error"
          flash[:error] = _("Error while leaving Active Directory domain: %s") % e.message
          render :index and return
        else
          Rails.logger.debug "ERROR INSPECT #{e.inspect}"
          flash[:error] = _("Error while saving Active Directory client configuration.")
        end
      end
    else #REST API
      Rails.logger.debug "XML RPX CALL"
      yapi_perm_check "activedirectory.write"
      args = params["activedirectory"]
      args = {} if args.nil?

      ad = Activedirectory.find
      ad.load args
      ad.save

      respond_to do |format|
        format.xml  { render :xml => ad.to_xml}
        format.json { render :json => ad.to_json}
      end
    end
    
  end

  # GET action
  # Read AD client settings
  def show
    yapi_perm_check "activedirectory.read"
    ad = Activedirectory.find

    respond_to do |format|
      format.xml  { render :xml => ad.to_xml}
      format.json { render :json => ad.to_json}
    end
  end

  # See update
  def create
    update
  end

end
