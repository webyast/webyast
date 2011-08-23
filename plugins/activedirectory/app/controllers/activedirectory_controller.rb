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
class ActivedirectoryController < ApplicationController

  before_filter :login_required

  # Initialize GetText and Content-Type.
  init_gettext 'webyast_activedirectory'

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
   
  # PUT action
  # Write AD client configuration
  def update
    yapi_perm_check "activedirectory.write"

    args	= params["activedirectory"]
    args	= {} if args.nil?
		  	
    ad = Activedirectory.find
    ad.load args
    ad.save

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
