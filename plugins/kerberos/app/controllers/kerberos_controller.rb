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
# = Kerberos controller
# Provides access to configuration of Kerberos client 
class KerberosController < ApplicationController
  def index
    authorize! :read, Kerberos
    begin
      @kerberos = Kerberos.find
      Rails.logger.debug "kerberos: #{@kerberos.inspect}"
    rescue Exception => error
      flash[:error] = _("Cannot read Kerberos client configuraton.")
      Rails.logger.error "ERROR: #{error.inspect}"
      @kerberos = nil
    end

    respond_to do |format|
      format.html
      format.xml  {
        if @kerberos
          render :xml => @kerberos.to_xml(:dasherize => false)
        else
          head :not_found
        end
      }
    end
  end

  def update
    authorize! :write, Kerberos
    begin
      #translate from text to boolean
      params[:kerberos][:enabled] = params[:kerberos][:enabled] == "true"
      @kerberos = Kerberos.new(params[:kerberos]).save
      flash[:message] = _("Kerberos client configuraton successfully written.")
    rescue Exception => error  
      flash[:error] = _("Error while saving Kerberos client configuration.")
      Rails.logger.error "ERROR: #{error.inspect}"
      render :index and return
    end
    
    redirect_success
  end

  # GET action
  # Read Kerberos client settings
  # Requires read permissions for Kerberos client YaPI.
  def show
    authorize! :read, Kerberos

    kerberos = Kerberos.find

    respond_to do |format|
      format.xml  { render :xml => kerberos.to_xml}
      format.json { render :json => kerberos.to_json}
    end
  end
   
  # See update
  def create
    update
  end

end
