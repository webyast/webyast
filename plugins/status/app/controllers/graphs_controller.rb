include ApplicationHelper

require 'metric'
require 'graph'
require 'uri'

#
# Controller that exposes graph description in a RESTful
# way.
#
# GET /grapsh returns all described graphs for the system status
#
# GET /metrics/id returns one graph description
#
class GraphsController < ApplicationController
  before_filter :login_required

  private

  def create_limit(graphs, label = "", limits = {})
    #todo
    return limits
  end

  public

  # POST /graphs
  # POST /graphs.xml
  def create
    permission_check("org.opensuse.yast.system.status.writelimits")      

    #find the correct plugin path for the config file
    plugin_config_dir = "#{RAILS_ROOT}/config" #default
    Rails.configuration.plugin_paths.each do |plugin_path|
      if File.directory?(File.join(plugin_path, "status"))
        plugin_config_dir = plugin_path+"/status/config"
        Dir.mkdir(plugin_config_dir) unless File.directory?(plugin_config_dir)
        break
      end
    end
    limits = Hash.new
    limits = create_limit(params["graphs"])
#    f = File.open(File.join(plugin_config_dir, "status_configuration.yaml"), "w")
#    f.write(limits.to_yaml)
#    f.close
    render :text => "OK"
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
  def show
    permission_check("org.opensuse.yast.system.status.read")
    @graph = Graph.find(params[:id], params[:checklimits] || false)
  end
end
