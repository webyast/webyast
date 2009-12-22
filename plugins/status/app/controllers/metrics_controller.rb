include ApplicationHelper

require 'metric'
require 'uri'

#
# Controller that exposes collectd metrics in a RESTful
# way.
#
# GET /metrics returns all metrics (with no data)
#
# GET /metrics/id returns one metric.
# As the id contains "/" you need to URI encode it.
#
# ie: /metrics/myhost.com%2Ffscache-Cookies%2Ffscache_stat-idx
#
class MetricsController < ApplicationController
  before_filter :login_required

  DEFAULT_TIMEFRAME=300

  private

  def create_limit(status, label = "", limits = {})
    if status.is_a? Hash
      status.each do |key, value|
        if key=="limit" && value.is_a?(Hash) && value["value"].to_f>0
          limit = Hash.new
          limit["value"] = value["value"].to_f
          limit["maximum"] = value["maximum"]
          limits[label] = limit
        end
        next_label = ""
        if label.blank?
          next_label = key
        else
          next_label = label+ "/" + key
        end
        create_limit(value, next_label, limits) if value.is_a? Hash
      end
    end
    return limits
  end

  public

  # POST /status
  # POST /status.xml
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
    limits = create_limit(params["status"])
    f = File.open(File.join(plugin_config_dir, "status_configuration.yaml"), "w")
    f.write(limits.to_yaml)
    f.close
    render :text => "OK"
  end

  # GET /status
  # GET /status.xml
  #
  def index

    conditions = {}
    
    # support filtering by host, plugin, plugin_instance ...
    [:host, :plugin, :type, :plugin_instance, :type_instance, :plugin_full, :type_full ].each do |key|
      if params.has_key?(key)
        conditions[key] = params[key]
      end
    end
    
    @metric = Metric.find(:all, conditions)

    @data = false
    @start = nil
    @stop = nil
 
    render :show    
  end

  # GET /status/1
  # GET /status/1.xml
  def show
    #permission_check("org.opensuse.yast.system.status.read")
    @metric = Metric.find(params[:id])
    @stop = params[:stop].blank? ? Time.now : Time.at(params[:stop].to_i)
    @start = params[:start].blank? ? @stop - DEFAULT_TIMEFRAME : Time.at(params[:start].to_i)
    @data = true
  end
end
