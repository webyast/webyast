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
# = Ldap controller
# Provides access to configuration of LDAP client 

#require 'client_exception'

class LdapController < ApplicationController
  # escape_javascript()
  include ActionView::Helpers::JavaScriptHelper

  # Initialize GetText and Content-Type.
  FastGettext.add_text_domain "webyast_ldap", :path => "locale"
 
  def index
    authorize! :read, Ldap

    begin
      @ldap = Ldap.find
      Rails.logger.debug "ldap: #{@ldap.inspect}"
    rescue Exception => error
      flash[:error] = _("Cannot read LDAP client configuraton.")
      Rails.logger.error "ERROR: #{error.inspect}"
      @ldap = nil
      render :index and return
    end

    head :not_found and return unless @ldap

    respond_to do |format|
      format.html
      format.xml  { render :xml => @ldap.to_xml }
    end
  end

  # try to get base DN provided by given LDAP server
  def fetch_dn
    authorize! :read, Ldap
    fetched = Ldap.fetch(params[:server])

    respond_to do |format|
      format.js { render :text => "$('#ldap_base_dn').val('#{escape_javascript(fetched["dn"])}');" }
    end
  end

  def update
    authorize! :write, Ldap

    begin
      @ldap = Ldap.find

      if params[:ldap].present?
        @ldap.load params[:ldap]
        #translate from text to boolean
        @ldap.tls = params[:ldap][:tls] == "true"
        @ldap.enabled = params[:ldap][:enabled] == "true"
      else
        @ldap.enabled = false
      end

      @ldap.save
      flash[:message] = _("LDAP client configuraton successfully written.") if request.format.html?
    rescue Exception => error
      flash[:error] = _("Error while saving LDAP client configuration.") if request.format.html?
      Rails.logger.error "ERROR: #{error.inspect}"

      respond_to do |format|
        format.html {redirect_to :action => :index}
        format.xml  {render :xml => @ldap.to_xml, :status => 500}
        format.json {render :json => @ldap.to_json, :status => 500}
      end

      return
    end

    respond_to do |format|
      format.html {redirect_to root_path}
      format.xml  {render :xml => @ldap.to_xml}
      format.json {render :json => @ldap.to_json}
    end
  end
  
  # GET action
  # Read LDAP client settings
  # If special parameter 'fetch_dn' is present, return base DN supported by given server
  #
  # Requires read permissions for LDAP client YaPI.
  def show
    authorize! :read, Ldap

    if params["fetch_dn"]
      dn = Ldap.fetch(params["server"])
      respond_to do |format|
        format.xml  { render :xml => dn.to_xml}
        format.json { render :json => dn.to_json}
      end
      return
    end

    ldap = Ldap.find

    respond_to do |format|
      format.xml  { render :xml => ldap.to_xml}
      format.json { render :json => ldap.to_json}
    end
  end

  # See update
  def create
    update
  end

end
