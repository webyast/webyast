#--
# Copyright (c) 2009, 2010 Novell, Inc.
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
# = Hostname controller
# Provides access to hostname settings for authenticated users.
# Main goal is checking permissions.

class Network::HostnameController < ApplicationController

  before_filter :login_required
  before_filter(:only => [:show]) { |c| c.yapi_perm_check "network.read" }
  before_filter(:only => [:create, :update]) { |c| c.yapi_perm_check "network.write"}

  # Sets hostname settings. Requires write permissions for network YaPI.
  def update
    root = params[:hostname]
    if root == nil
      raise InvalidParameters.new :hostname => "Missing"
    end
    
    hostname = Hostname.new(root)
    hostname.save!
    show
  end

  # See update
  def create
    update
  end

  # Shows hostname settings. Requires read permission for network YaPI.
  def show
    @hostname = Hostname.find

    respond_to do |format|
      format.xml { render :xml => @hostname.to_xml( :root => "hostname", :dasherize => false ) }
      format.json { render :json => @hostname.to_json }
    end
  end

end
