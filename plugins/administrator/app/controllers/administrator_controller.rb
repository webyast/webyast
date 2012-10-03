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
# = Administrator controller
# Provides access to configuration of system administrator.

class AdministratorController < ApplicationController
  
  public

  def index
    authorize! :read, Administrator
    @write_permission = can? :write, Administrator
    
    @administrator	= Administrator.find
    @administrator.confirm_password	= ""
    params[:firstboot] = 1 if Basesystem.new.load_from_session(session).in_process?

    respond_to do |format|
      format.html
      format.xml  { render :xml => @administrator.to_xml(:dasherize => false) }
      format.json { render :json => @administrator.to_json }
    end
  end

  def update
    authorize! :write, Administrator
    @administrator	= Administrator.find

    admin	= params["administrator"]
    @administrator.password	= admin["password"]
    @administrator.aliases	= admin["aliases"]
    
    #validate data also here, if javascript in view is off
    
    unless admin["aliases"].empty?
      admin["aliases"].split(",").each do |mail|
        #only check emails, not local users
        if mail.include?("@") && mail !~ /^.+@.+$/ #only trivial check
          flash[:error] = _("Enter a valid e-mail address.")
          redirect_to :action => "index"
          return
        end
      end
    end

    if admin["password"] != admin["confirm_password"] && ! params.has_key?("save_aliases")
      flash[:error] = _("Passwords do not match.")
      redirect_to :action => "index"
      return
    end

    # only save selected subset of administrator data:
    @administrator.password	= nil if params.has_key? "save_aliases"

    # we cannot pass empty string to rest-service
    @administrator.aliases = "NONE" if @administrator.aliases == ""

    begin
      @administrator.save
      flash[:notice] = _('Administrator settings have been written.')
    rescue Exception => error  
      flash[:error] = _("Error while saving administrator settings.")
      Rails.logger.error "ERROR: #{error.inspect}"
      Rails.logger.error "backtrace: #{error.backtrace.join("\n")}"

      respond_to do |format|
        format.html { redirect_to :action => :index }
        format.xml  { head :internal_server_error }
        format.json { head :internal_server_error }
      end
    end

    # check if mail is configured; during initial workflow, only warn if mail configuration does not follow
    if admin["aliases"] != "" && (defined?(Mail) == 'constant' && Mail.class == Class) &&
        (!Basesystem.new.load_from_session(session).following_steps.any? { |h| h[:controller] == "mail" })
      @mail = Mail.find :one
      if @mail && (@mail.smtp_server.nil? || @mail.smtp_server.empty?)
        flash[:warning] = _("Mail alias was set but outgoing mail server is not configured.")
      end
    end

    respond_to do |format|
      format.html { redirect_success }
      format.xml  { render :xml => @administrator.to_xml(:dasherize => false) }
      format.json { render :json => @administrator.to_json }
    end
  end

  # See update
  def create
    update
  end

end
