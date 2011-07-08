#--
# Copyright (c) 2009 Novell, Inc.
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
# = Routing controller
# Provides access to routes settings for authenticated users.
# Main goal is checking permissions.
class Network::RoutesController < ApplicationController

  before_filter :login_required
  before_filter(:only => [:index, :show]) { |c|    c.yapi_perm_check "network.read" }
  before_filter(:only => [:create, :update]) { |c| c.yapi_perm_check "network.write"}

  # Sets route settings. Requires write permissions for network YaPI.
  def update
    # :route is specified, :routes is sent by the ui :-/
    root = params[:route] || params[:routes]
    if root == nil
      raise InvalidParameters.new :route => "Missing", :routes => "Missing"
    end
    @route = Route.new(root)
    @route.save!
    show
  end


  # Shows route settings. Requires read permission for network YaPI.
  def show
    @route = Route.find(params[:id])

    respond_to do |format|
      format.xml { render :xml => @route.to_xml( :root => "route", :dasherize => false ) }
      format.json { render :json => @route.to_json }
    end
  end

  def index
#    routes_a = Route.find(:all).values
    routes_a = Route.find(:all)
    logger.error "Route A #{routes_a.inspect}"
    respond_to do |format|
      format.xml { render :xml => routes_a.to_xml( :root => "routes", :dasherize => false ) }
      format.json { render :json => routes_a.to_json }
    end    
  end

end

