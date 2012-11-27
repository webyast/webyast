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

  DEFAULT_TIMEFRAME=300

  # GET /metrics
  # GET /metrics.xml
  #
  def index
    authorize! :read, Metric
    conditions = {}
    # support filtering by host, plugin, plugin_instance ...
    [:host, :plugin, :type, :plugin_instance, :type_instance, :plugin_full, :type_full ].each do |key|
      if params.has_key?(key)
        conditions[key] = params[key]
      end
    end
    @metric = Metric.find(:all, conditions)
    @data = nil

    respond_to do |format|
      format.html { redirect_to :controller => "status" }
      format.json { render :json => @metric.to_json }
      format.xml { render :xml => @metric.to_xml(:root => "metrics", :data => @data, :dasherize => false) }
    end
  end

  # GET /metrics/1
  # GET /metrics/1.xml
  def show
    authorize! :read, Metric
    @metric = Metric.find(params[:id]) || raise ActionController::RoutingError.new('Not Found')
    data_opts = {}
    data_opts[:stop] = params[:stop].blank? ? Time.now : Time.at(params[:stop].to_i)
    data_opts[:start] = params[:start].blank? ? data_opts[:stop] - DEFAULT_TIMEFRAME : Time.at(params[:start].to_i)
#    Rails.logger.info "rendering metric #{id} from #{data_opts[:start].to_i} to #{data_opts[:stop].to_i}"

    @data = @metric.data(data_opts)
    respond_to do |format|
      format.html { redirect_to :controller => "status" }
      format.json { render :json => @metric.to_json }
      format.xml { render :xml => @metric.to_xml(:root => "metrics", :data => @data, :dasherize => false) }
    end
  end
end
