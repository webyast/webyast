include ApplicationHelper

require 'metric'
require 'graph'
require 'uri'

#
# Controller that exposes graph description in a RESTful
# way.
#
# GET /graphs returns all described graphs for the system status
#
# GET /graphs/id returns one graph description
#
class GraphsController < ApplicationController
  before_filter :login_required

  public

  # PUT /graphs
  def update
    permission_check("org.opensuse.yast.system.status.writelimits")      
    if params.has_key?(:graphs)
      @graph = Graph.new(params[:id], params[:graphs])
      @graph.save
    else
      logger.warn("No argument to update")
      raise InvalidParameters.new :graphs => "Missing"
    end
    render :show
  end

  # GET /graphs
  # GET /graphs.xml
  #
  def index
    permission_check("org.opensuse.yast.system.status.read")
    @graph = Graph.find(:all,  params[:checklimits] || false )
    render :show    
  end

  # GET /graphs/1
  # GET /graphs/1.xml
  #
  def show
    permission_check("org.opensuse.yast.system.status.read")
    @graph = Graph.find(params[:id], params[:checklimits] || false)
  end
end
