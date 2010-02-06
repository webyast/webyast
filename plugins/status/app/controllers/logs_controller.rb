include ApplicationHelper

require 'log'

#
# Controller that exposes log files in a RESTful
# way.
#
# GET /logs returns a description of all available logfiles
#
# GET /logs/id returns the content of a logfile with the id "id"
#

class LogsController < ApplicationController
    
  # GET /logs
  # GET /logs.xml
  #
  def index
    permission_check("org.opensuse.yast.system.status.read")
    @logs = Log.find(:all)
    render :show    
  end
  
  # GET /logs/system
  # GET /logs/system.xml
  #
  def show
    permission_check("org.opensuse.yast.system.status.read")
    @logs = Log.find(params[:id])
    @logs.evaluate_content(params[:pos_begin], params[:lines])
    render :show    
  end

end
