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
# = DNS controller
# Provides access to DNS settings for authenticated users.
# Main goal is checking permissions.
class Network::DnsController < ApplicationController

  before_filter :login_required
  before_filter(:only => [:show]) { |c| c.yapi_perm_check "network.read" }
  before_filter(:only => [:create, :update]) { |c| c.yapi_perm_check "network.write"}

  # Sets hostname settings. Requires write permissions for network YaPI.
  def update
    root = params[:dns]
    if root == nil
      raise InvalidParameters.new :dns => "Missing"
    end
    
    root["searches"] = (root["searches"] || "").split
    root["nameservers"] = (root["nameservers"] || "").split
    
    @dns = DNS.new(root)
    @dns.save!
    show
  end

  # See update
  def create
    update
  end

  # Shows hostname settings. Requires read permission for network YaPI.
  def show
    @dns = DNS.find

    respond_to do |format|
      format.xml { render :xml => @dns.to_xml( :root => "dns", :dasherize => false ) }
      format.json { render :json => @dns.to_json }
    end
  end

end
