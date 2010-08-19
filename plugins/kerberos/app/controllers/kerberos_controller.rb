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

  before_filter :login_required

  # GET action
  # Read Kerberos client settings
  # Requires read permissions for Kerberos client YaPI.
  def show
    yapi_perm_check "kerberos.read"

    kerberos = Kerberos.find

    respond_to do |format|
      format.xml  { render :xml => kerberos.to_xml}
      format.json { render :json => kerberos.to_json}
    end
  end
   
  # PUT action
  # Write Kerberos client configuration
  # Requires write permissions for Kerberos client YaPI.
  def update
    yapi_perm_check "kerberos.write"

    args	= params["kerberos"]
		  	
    kerberos = Kerberos.new # do not read, it can take much time because of DNS
    kerberos.load args
    kerberos.save

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
