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

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require "log"
require "graph"
require "metric"
require "plugin"

class StatusControllerTest < ActionController::TestCase


  # return contents of a fixture file +file+
  def fixture(file)
    ret = open(File.join(File.dirname(__FILE__), "..", "fixtures", file)) { |f| YAML.load(f) }
    ret
  end

  def setup
    StatusController.any_instance.stubs(:login_required)
    @controller = StatusController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
    @response_logs = fixture "logs.yaml"
    @response_logs_system = fixture "logs_system.yaml"
    Log.stubs(:find).with(:all).returns(@response_logs)
    Log.any_instance.stubs(:evaluate_content).returns(@response_logs_system)

    @response_graphs = fixture "graphs.yaml"
    Graph.stubs(:find).with(:all, true).returns(@response_graphs)
    @response_graphs_memory = fixture "graphs_memory.yaml"
    Graph.stubs(:find).with("Memory",true).returns(@response_graphs_memory)
    @response_graphs_disk = fixture "graphs_disk.yaml"
    Graph.stubs(:find).with("Disk",true).returns(@response_graphs_disk)

    @response_plugins = fixture "plugins.yaml"
    Plugin.stubs(:find).with(:all).returns(@response_plugins)

    @response_metrics = fixture "metric.yaml"
    Metric.stubs(:find).with(:all).returns(@response_metric)
    @response_metrics_memory_free = fixture "webyast+memory+memory-free.yaml"
    Metric.stubs(:find).with("WebYaST+memory+memory-free").returns(@response_metrics_memory_free)
    @response_metrics_memory_used = fixture "webyast+memory+memory-used.yaml"
    Metric.stubs(:find).with("WebYaST+memory+memory-used").returns(@response_metrics_memory_used)
    @response_metrics_memory_cached = fixture "webyast+memory+memory-cached.yaml"
    Metric.stubs(:find).with("WebYaST+memory+memory-cached").returns(@response_metrics_memory_cached)
    @response_metrics_df_root = fixture "webyast+df+df-root.yaml"
    Metric.stubs(:find).with("WebYaST+df+df-root").returns(@response_metrics_df_root)
  end


  #first index call
  def test_index
    get :index
    assert_response :success
    assert_valid_markup
    assert assigns(:graphs)
  end


  # now permissions in index
  def test_index_no_permissions

    get :index
    assert_response :success
    assert_valid_markup
    assert assigns(:graphs)
#    assert assigns(:permissions), "permissions is not assigned"
#    assert !assigns(:permissions)[:read], "read permission is granted"
#    assert !assigns(:permissions)[:writelimits], "writelimits permission is granted"
  end


end

