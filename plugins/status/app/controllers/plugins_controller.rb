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
