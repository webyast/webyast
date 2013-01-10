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
# Provides access to network routes settings for authenticated users.

class Network::RoutesController < ApplicationController

  before_filter(:only => [:show, :index]) { |c| c.authorize! :read, Network }
  before_filter(:only => [:create, :update]) { |c| c.authorize! :write, Network }

  # Sets route settings. Requires write permissions for network YaPI.
  # :route is specified, :routes is sent by the ui :-/

  def update
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
    # RORSCAN_INL: Is not a Information Exposure cause all data can be read
    @route = Route.find(params[:id])
    Rails.logger.debug "** Route #{@route.inspect}"

    head :not_found and return if @route.nil?

    respond_to do |format|
      format.xml { render :xml => @route.to_xml(:dasherize => false) }
      format.json { render :json => @route.to_json }
    end
  end

  def index
    @routes = Route.find(:all)
    Rails.logger.debug "** Routes #{@routes.inspect}"
    
    respond_to do |format|
      format.xml { render :xml => @routes.to_xml(:dasherize => false) }
      format.json { render :json => @routes.to_json }
    end
  end

end

