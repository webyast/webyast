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
class LdapController < ApplicationController

  before_filter :login_required

  # GET action
  # Read LDAP client settings
  # If special parameter 'fetch_dn' is present, return base DN supported by given server
  #
  # Requires read permissions for LDAP client YaPI.
  def show
    yapi_perm_check "ldap.read"

    if params["fetch_dn"]
	dn	= Ldap.fetch(params["server"])
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
   
  # PUT action
  # Write LDAP client configuration
  # Requires write permissions for LDAP client YaPI.
  def update
    yapi_perm_check "ldap.write"

    args	= params["ldap"]
		  	
    ldap = Ldap.find
    ldap.load args unless args.nil?
    ldap.save

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
