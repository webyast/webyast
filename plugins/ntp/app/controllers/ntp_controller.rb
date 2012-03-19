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

class NtpController < ApplicationController

  def show
    ntp = Ntp.find

    respond_to do |format|
	    format.xml  { render :xml => ntp.to_xml}
	    format.json { render :json => ntp.to_json }
    end
  end
   
  def update
    root = params["ntp"]
    if root == nil || root == {} 
      raise InvalidParameters.new :ntp => "Missing"
    end
	
    ntp = Ntp.new(root)
    authorize!(:synchronize, Ntp) if ntp.actions[:synchronize]
    authorize!(:setserver, Ntp)   if (ntp.actions[:ntp_server]!=Ntp.get_servers)
    ntp.save	

    show
  end

  # See update
  def create
    update
  end

end
