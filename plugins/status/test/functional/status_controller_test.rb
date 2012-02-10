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
require File.join(RailsParent.parent, "test","devise_helper")
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

  def rights_enable(enable = true)
    if enable
      StatusController.any_instance.stubs(:authorize!).with(:read, Metric).returns(true)
      StatusController.any_instance.stubs(:authorize!).with(:writelimits, Metric).returns(true)
      StatusController.any_instance.stubs(:can?).with(:read, Metric).returns(true)
      StatusController.any_instance.stubs(:can?).with(:writelimits, Metric).returns(true)
    else
      @excpt = CanCan::AccessDenied.new()
      StatusController.any_instance.stubs(:authorize!).with(:read, Metric).raises(@excpt)
      StatusController.any_instance.stubs(:authorize!).with(:writelimits, Metric).raises(@excpt)
      StatusController.any_instance.stubs(:can?).with(:read, Metric).returns(false)
      StatusController.any_instance.stubs(:can?).with(:writelimits, Metric).returns(false)
    end
  end
   
  def init_data
    Log.stubs(:find).with(:all).returns(@response_logs)
    Log.stubs(:find).with('system').returns(@response_logs[0])
    Log.any_instance.stubs(:evaluate_content).returns(@response_logs_system)
    Graph.stubs(:find).with(:all, true).returns(@response_graphs)
    Graph.stubs(:find).with(:all).returns(@response_graphs)
    Graph.stubs(:find).with("Memory",true).returns(@response_graphs_memory)
    Graph.stubs(:find).with("Memory").returns(@response_graphs_memory)
    Graph.stubs(:find).with("Disk",true).returns(@response_graphs_disk)
    Graph.stubs(:find).with("Disk").returns(@response_graphs_disk)
    Plugin.stubs(:find).with(:all).returns(@response_plugins)
    Metric.stubs(:find).with(:all).returns(@response_metric)
    Metric.stubs(:find).with("WebYaST+memory+memory-free").returns(@response_metrics_memory_free)
    Metric.stubs(:find).with("WebYaST+memory+memory-used").returns(@response_metrics_memory_used)
    Metric.stubs(:find).with("WebYaST+memory+memory-cached").returns(@response_metrics_memory_cached)
    Metric.stubs(:find).with("WebYaST+df+df-root").returns(@response_metrics_df_root)
  end

  def setup
    devise_sign_in

    @response_logs = fixture "logs.yaml"
    @response_logs_system = fixture "logs_system.yaml"
    @response_graphs = fixture "graphs.yaml"
    @response_graphs_memory = fixture "graphs_memory.yaml"
    @response_graphs_disk = fixture "graphs_disk.yaml"
    @response_plugins = fixture "plugins.yaml"
    @response_metrics = fixture "metric.yaml"
    @response_metrics_memory_free = fixture "webyast+memory+memory-free.yaml"
    @response_metrics_memory_used = fixture "webyast+memory+memory-used.yaml"
    @response_metrics_memory_cached = fixture "webyast+memory+memory-cached.yaml"
    @response_metrics_df_root = fixture "webyast+df+df-root.yaml"
  end

  #first index call
  def test_index
    init_data
    rights_enable
    get :index
    assert_response :success
    assert_valid_markup
    assert assigns(:graphs)
  end

  # now permissions in index
  def test_index_no_permissions
    init_data
    rights_enable(false)
    get :index
    assert_response 302
    assert !assigns(:graphs)
  end

  #testing show summary AJAX call; limit CPU user reached
  def test_show_summary_limit_reached
    init_data
    rights_enable
    get :show_summary
    assert_response :success
    assert_tag :tag=>"a", :attributes => { :class => "warning_message"}, :parent => { :tag => "div"}, :content=> /Limits exceeded for Memory\/cached/
    assert_tag :tag=>"a", :attributes => { :class => "warning_message"}, :parent => { :tag => "div"}, :content=>/Registration is missing/
    assert_tag :tag=>"a", :attributes => { :class => "warning_message"}, :parent => { :tag => "div"}, :content=>/Mail configuration test not confirmed/

  end

  #testing show summary AJAX call; no permissions
  def test_show_summary_no_permission
    init_data
    rights_enable(false)
    get :show_summary
    assert_response :success
    assert_tag :tag=>"a", :attributes => { :class => "warning_message"}, :parent => { :tag => "div"}
    assert_tag "Status not available (no permissions)"
  end

  #testing show summary AJAX call; Server Error
  def test_show_summary_server_error_1
    rights_enable
    init_data
    timestamp = Time.at(1264006620)
    @excpt = CollectdOutOfSyncError.new(timestamp)
    Graph.stubs(:find).with(:all, true).raises(@excpt)

    get :show_summary
    assert_response :success
    assert_tag :tag=>"a", :attributes => { :class => "warning_message" }, :parent => { :tag => "div"}
    assert_tag "Collectd is out of sync. Status information can be expected at #{Time.at(timestamp).ctime}."
  end

  #testing show summary AJAX call; Server Error
  def test_show_summary_server_error_2
    rights_enable
    init_data
    @excpt = ServiceNotRunning.new("collectd")
    Graph.stubs(:find).with(:all, true).raises(@excpt)

    get :show_summary
    assert_response :success
    assert_tag :tag=>"a", :attributes => { :class => "warning_message" }, :parent => { :tag => "div"}
    assert_tag "Status not available."
  end

  #testing evaluate_values AJAX call
  def test_show_evaluate_values_1
    rights_enable
    init_data
    Time.stubs(:now).returns(Time.at(1264006620))
    get :evaluate_values,  { :group_id => "Memory", :graph_id => "Memory", :minutes => "5" }
    assert_response :success
    assert_tag :tag =>"script",
               :attributes => { :type => "text/javascript" }
  end

  #testing evaluate_values AJAX call
  def test_show_evaluate_values_with_other_id
    rights_enable
    init_data
    Time.stubs(:now).returns(Time.at(1264006620))
    get :evaluate_values,  { :group_id => "Disk", :graph_id => "root" }
    assert_response :success
    assert_tag :tag =>"script",
               :attributes => { :type => "text/javascript" }
  end

  #testing evaluate_values AJAX call
  def test_show_evaluate_values_with_invalid_id
    rights_enable
    init_data
    Graph.stubs(:find).with('not_found').returns(nil)
    Time.stubs(:now).returns(Time.at(1264006620))
    get :evaluate_values,  { :group_id => "not_found", :graph_id => "not_found" }
    assert_response :success
  end

  #testing confirming status
  def test_confirm_status
    rights_enable
    init_data
    post :confirm_status, { :param=>"Test mail received", :url=>"/mail/state", }
    assert_response :redirect
  end

  #testing  call ajax_log_custom
  def test_show_ajax_log_custom
    rights_enable
    init_data
    get :ajax_log_custom, { :id => "system", :lines => "50" }
    assert_response :success
    assert_tag "\nJul 20 15:11:35 f77 dhclient: XMT: Solicit on eth0, interval 119610ms.\nJul 20 15:13:34 f77 dhclient: XMT: Solicit on eth0, interval 125170ms.\n"
  end

  #testing  call ajax_log_custom
  def test_show_ajax_log_custom_without_params
    rights_enable
    init_data
    get :ajax_log_custom, { }
    assert_response 500
  end

  #testing  call ajax_log_custom which returns a permission error
  def test_show_ajax_log_custom_no_permission
    rights_enable( false )
    init_data
    get :ajax_log_custom, { :id => "system", :lines => "50" }
    assert_response 302
  end

  #call for edit limits
  def test_edit
    rights_enable
    init_data
    get :edit
    assert_response :success
    assert assigns(:graphs)
  end

  #writing limits
  def test_commit_limits
    rights_enable
    init_data
    Graph.stubs(:plugin_config_dir).returns("/tmp")
    Graph.stubs(:parse_config).returns(
    {"Network"=>{"y_decimal_places"=>0, "headline"=>"_(\"Network\")", "y_scale"=>1, "y_label"=>"_(\"MByte/s\")", "single_graphs"=>[{"lines"=>[{"label"=>"received", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_column"=>"rx", "metric_id"=>"interface+if_packets-eth0"}, {"label"=>"sent", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_column"=>"tx", "metric_id"=>"interface+if_packets-eth0"}], "headline"=>"eth0", "cummulated"=>"false", "linegraph"=>"true"}], "y_max"=>nil}, "CPU"=>{"y_decimal_places"=>0, "headline"=>"_(\"CPU\")", "y_scale"=>1, "y_label"=>"_(\"Percent\")", "single_graphs"=>[{"lines"=>[{"label"=>"idle", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_id"=>"cpu-6+cpu-idle"}, {"label"=>"user", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_id"=>"cpu-6+cpu-user"}], "headline"=>"CPU-6", "cummulated"=>"false", "linegraph"=>"true"}], "y_max"=>100}, "Disk"=>{"y_decimal_places"=>0, "headline"=>"_(\"Disk\")", "y_scale"=>1073741824, "y_label"=>"_(\"GByte\")", "single_graphs"=>[{"lines"=>[{"label"=>"used", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_column"=>"used", "metric_id"=>"df+df-root"}, {"label"=>"free", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_column"=>"free", "metric_id"=>"df+df-root"}], "headline"=>"root", "cummulated"=>"true", "linegraph"=>"false"}, {"lines"=>[{"label"=>"used", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_column"=>"used", "metric_id"=>"df+df-home"}, {"label"=>"free", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_column"=>"free", "metric_id"=>"df+df-home"}], "headline"=>"home", "cummulated"=>"true", "linegraph"=>"false"}], "y_max"=>nil}, "Memory"=>{"y_decimal_places"=>0, "headline"=>"_(\"Memory\")", "y_scale"=>1048567, "y_label"=>"_(\"MByte\")", "single_graphs"=>[{"lines"=>[{"label"=>"cached", "limits"=>{"max"=>"0", "min"=>"0", "reached"=>true}, "metric_id"=>"memory+memory-cached"}, {"label"=>"used", "limits"=>{"max"=>"0", "min"=>"0", "reached"=>false}, "metric_id"=>"memory+memory-used"}, {"label"=>"free", "limits"=>{"max"=>"0", "min"=>"40", "reached"=>false}, "metric_id"=>"memory+memory-free"}], "headline"=>"Memory", "cummulated"=>"true", "linegraph"=>"false"}], "y_max"=>nil}})
    put :save,  {"value/Memory/Memory/cached"=>"", "measurement/CPU/CPU-0/user"=>"max", "value/CPU/CPU-0/user"=>"", "value/CPU/CPU-1/user"=>"", "value/Network/eth0/received"=>"", "measurement/CPU/CPU-1/idle"=>"max", "measurement/CPU/CPU-0/idle"=>"max", "measurement/Network/eth0/sent"=>"max", "value/CPU/CPU-1/idle"=>"", "measurement/Network/eth0/received"=>"max", "measurement/Memory/Memory/free"=>"min", "measurement/Memory/Memory/used"=>"max", "value/Memory/Memory/used"=>"", "value/CPU/CPU-0/idle"=>"", "value/Network/eth0/sent"=>"", "value/Memory/Memory/free"=>"40", "measurement/Memory/Memory/cached"=>"max", "measurement/CPU/CPU-1/user"=>"max"}
    assert_response :redirect
    assert_redirected_to :controller => "status", :action => "index"
  end

  #writing limits without rights
  def test_commit_limits_no_rights
    rights_enable( false )
    init_data
    put :save,  {"value/Memory/Memory/cached"=>"", "measurement/CPU/CPU-0/user"=>"max", "value/CPU/CPU-0/user"=>"", "value/CPU/CPU-1/user"=>"", "value/Network/eth0/received"=>"", "measurement/CPU/CPU-1/idle"=>"max", "measurement/CPU/CPU-0/idle"=>"max", "measurement/Network/eth0/sent"=>"max", "value/CPU/CPU-1/idle"=>"", "measurement/Network/eth0/received"=>"max", "measurement/Memory/Memory/free"=>"min", "measurement/Memory/Memory/used"=>"max", "value/Memory/Memory/used"=>"", "value/CPU/CPU-0/idle"=>"", "value/Network/eth0/sent"=>"", "value/Memory/Memory/free"=>"40", "measurement/Memory/Memory/cached"=>"max", "measurement/CPU/CPU-1/user"=>"max"}
    assert_response 302
  end

end

