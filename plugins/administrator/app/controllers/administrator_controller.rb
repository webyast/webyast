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

  before_filter :login_required

  # GET action
  # Read administrator settings (currently mail aliases).
  # Requires read permissions for administrator YaPI.
  def show
    yapi_perm_check "administrator.read"

    @admin = Administrator.instance
    @admin.read_aliases

    respond_to do |format|
      format.xml  { render :xml => @admin.to_xml(:root => "administrator", :indent=>2), :location => "none" }
      format.json { render :json => @admin.to_json, :location => "none" }
    end
  end
   
  # PUT action
  # Write administrator settings: mail aliases and/or password.
  # Requires write permissions for administrator YaPI.
  def update
    yapi_perm_check "administrator.write"
	
    data = params["administrator"]
    @admin = Administrator.instance
    @admin.read_aliases

    if data.has_key?(:password) && !data[:password].nil? && !data[:password].empty?
      @admin.save_password(data[:password])
    end

    if data.has_key?(:aliases) && !data[:aliases].nil?
      @admin.save_aliases(data[:aliases])
    end
    show
  end

  # See update
  def create
    update
  end

end
