#--
# Webyast Webservice framework
#
# Copyright (C) 2009, 2010 Novell, Inc. 
#   This library is free software; you can redistribute it and/or modify
# it only under the terms of version 2.1 of the GNU Lesser General Public
# License as published by the Free Software Foundation. 
#
#   This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more 
# details. 
#
#   You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software 
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#++


class ResourcesController < ApplicationController
  require "resource_registration"
  caches_action :index
  
  def index
    @resources = Resource.find :all
    @node = "Yast"

    respond_to do |format|
      format.html
      format.xml { render :xml => @resources.to_xml }
      format.json{ render :json=> @resources.to_json}
    end
  end

  def show
    logger.info params.inspect
    @resource = Resource.find(params[:id].tr('-','.')) #FIXME check if :id is passed
    unless @resource then
      render :file => "#{RAILS_ROOT}/public/404.html", :status => 404 and return 
    end
    @node = "Yast"
    respond_to do |format|
      format.html
      format.xml { render :xml => @resource.to_xml }
      format.json{ render :json=> @resource.to_json}
    end
  end
end
