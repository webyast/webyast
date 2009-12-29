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

  # GET /metrics
  # GET /metrics.xml
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

  # GET /metrics/1
  # GET /metrics/1.xml
  def show
    #permission_check("org.opensuse.yast.system.status.read")
    @metric = Metric.find(params[:id])
    @stop = params[:stop].blank? ? Time.now : Time.at(params[:stop].to_i)
    @start = params[:start].blank? ? @stop - DEFAULT_TIMEFRAME : Time.at(params[:start].to_i)
    @data = true
  end
end
