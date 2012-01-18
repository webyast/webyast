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
  layout 'main'
  
  private
  FastGettext.add_text_domain "webyast-root-user", :path => "locale"

  public

  def index
    authorize! :read, Administrator
    @write_permission = can? :write, Administrator
    
    @administrator	= Administrator.find
    @administrator.confirm_password	= ""
    params[:firstboot]	= 1 if Basesystem.new.load_from_session(session).in_process?
  end

  def update
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
      response = @administrator.save
      flash[:notice] = _('Administrator settings have been written.')
    rescue Exception => error  
      flash[:error] = _("Error while saving administrator settings.") 
      Rails.logger.error "ERROR: #{error.inspect}"
      render :index and return
    end

    # check if mail is configured; during initial workflow, only warn if mail configuration does not follow
    if admin["aliases"] != "" && (defined?(Mail) == 'constant' && Mail.class == Class) &&
        (!Basesystem.new.load_from_session(session).following_steps.any? { |h| h[:controller] == "mail" })
      @mail = Mail.find :one
      if @mail && (@mail.smtp_server.nil? || @mail.smtp_server.empty?)
        flash[:warning] = _("Mail alias was set but outgoing mail server is not configured (%s<i>change</i>%s).") % ['<a href="/mail">', '</a>']
      end
    end

    redirect_success
  end




  # GET action
  # Read administrator settings (currently mail aliases).
  # Requires read permissions for administrator YaPI.
  def show
    authorize! :read, Administrator

    admin = Administrator.find

    respond_to do |format|
      format.xml  { render :xml => admin.to_xml(:root => "administrator", :indent=>2), :location => "none" }
      format.json { render :json => admin.to_json, :location => "none" }
    end
  end
   
  # PUT action
  # Write administrator settings: mail aliases and/or password.
  # Requires write permissions for administrator YaPI.
#  def update
#    yapi_perm_check "administrator.write"
#	
#    data = params["administrator"]
#    if data
#      Administrator.new(data).save
#    end
#    show
#  end

  # See update
  def create
    update
  end

end
