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

include ApplicationHelper

require 'plugin'

#
# Controller that exposes WebYaST service plugins in a RESTful
# way.
#
# GET /plugins returns status information of all WebYaST plugins
#
# GET /plugins/id returns status information of a plugin with the id "id"
#

class PluginsController < ApplicationController
    
  # GET /plugins
  # GET /plugins.xml
  #
  def index
    permission_check("org.opensuse.yast.system.status.read")
    @plugins = Plugin.find(:all)
    render :show    
  end
  
  # GET /plugins/users
  # GET /plugins/users.xml
  #
  def show
    permission_check("org.opensuse.yast.system.status.read")
    @plugins = Plugin.find(params[:id])
    render :show    
  end

end
