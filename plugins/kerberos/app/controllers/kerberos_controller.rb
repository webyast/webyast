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

    @kerberos_missing = kerberos_missing?

    if @kerberos_missing
      flash[:warning] = missing_packages_text
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
      @kerberos = Kerberos.find

      if params[:kerberos].present?
        @kerberos.load params[:kerberos]
        #translate from text to boolean
        @kerberos.enabled = params[:kerberos][:enabled] == "true"
        @kerberos.dns_used = params[:kerberos][:use_dns] == "true"
      else
        @kerberos.enabled = false
      end

      @kerberos.save
      flash[:message] = _("Kerberos client configuraton successfully written.")
    rescue Exception => error
      flash[:error] = _("Error while saving Kerberos client configuration.")
      Rails.logger.error "ERROR: #{error.inspect}"
      Rails.logger.error "ERROR: #{error.backtrace.join("\n")}"

      respond_to do |format|
        format.html {redirect_to :action => :index}
        format.xml  {render :xml => @kerberos.to_xml, :status => 500}
        format.json {render :json => @kerberos.to_json, :status => 500}
      end

      return
    end

    if kerberos_missing?
      #hack to simple report user that part of kerberos missing, FIXME in future to better report problems
      @kerberos = { "error" => missing_packages_text }
    end
    respond_to do |format|
      format.html {redirect_to root_path}
      format.xml  {render :xml => @kerberos.to_xml}
      format.json {render :json => @kerberos.to_json}
    end
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

private 

  def running_64bit?
    `uname --hardware-platform`.chomp == 'x86_64'
  end

  def missing_packages_text
    if running_64bit?
      _("Kerberos cannot be enabled, because its pam plugin is missing. Please install pam_krb5 and pam_krb5-32bit packages.")
    else
      _("Kerberos cannot be enabled, because its pam plugin is missing. Please install pam_krb5 package.")
    end
  end

  def kerberos_missing?
    `rpm -q pam_krb5`
    kerberos_missing = $?.exitstatus != 0

    if running_64bit?
      `rpm -q pam_krb5-32bit`
      kerberos_missing ||= $?.exitstatus != 0
    end

    return kerberos_missing
  end

end
