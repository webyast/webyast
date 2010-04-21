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
require 'mocha'

require 'rexml/document'

def xml_cmp a, b
  a = REXML::Document.new(a.to_s)
  b = REXML::Document.new(b.to_s)

  normalized = Class.new(REXML::Formatters::Pretty) do
    def write_text(node, output)
      super(node.to_s.strip, output)
    end
  end

  normalized.new(indentation=0,ie_hack=false).write(node=a, a_normalized='')
  normalized.new(indentation=0,ie_hack=false).write(node=b, b_normalized='')

  a_normalized == b_normalized
end

class GraphTest < ActiveSupport::TestCase

  PARSE_CONFIG_1 ={"Network"=>{"y_scale"=>1, "y_label"=>"MByte", "single_graphs"=>[{"lines"=>[{"label"=>"received", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_column"=>"rx", "metric_id"=>"interface+if_packets-eth0"}, {"label"=>"sent", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_column"=>"tx", "metric_id"=>"interface+if_packets-eth0"}], "headline"=>"Network", "cummulated"=>"false", "linegraph"=>"false"}]}, "CPU"=>{"y_scale"=>1, "y_label"=>"Percent", "single_graphs"=>[{"lines"=>[{"label"=>"Idle", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_id"=>"cpu-0+cpu-idle"}, {"label"=>"Used", "limits"=>{"max"=>"10", "min"=>"0"}, "metric_id"=>"cpu-0+cpu-user"}], "headline"=>"CPU", "cummulated"=>"false", "linegraph"=>"false"}]}, "Disk"=>{"y_scale"=>1073741824, "y_label"=>"GByte", "single_graphs"=>[{"lines"=>[{"label"=>"used", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_column"=>"used", "metric_id"=>"df+df-root"}, {"label"=>"free", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_column"=>"free", "metric_id"=>"df+df-root"}], "headline"=>"root", "cummulated"=>"true", "linegraph"=>"false"}]}, "Memory"=>{"y_scale"=>1048567, "y_label"=>"MByte", "single_graphs"=>[{"lines"=>[{"label"=>"Used", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_id"=>"memory+memory-used"}, {"label"=>"Free", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_id"=>"memory+memory-free"}, {"label"=>"Cached", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_id"=>"memory+memory-cached"}], "headline"=>"Memory", "cummulated"=>"true", "linegraph"=>"false"}]}}

  PARSE_CONFIG_2 ={"Network"=>{"y_scale"=>1, "y_label"=>"MByte", "single_graphs"=>[{"lines"=>[{"label"=>"received", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_column"=>"rx", "metric_id"=>"interface+if_packets-eth0"}, {"label"=>"sent", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_column"=>"tx", "metric_id"=>"interface+if_packets-eth0"}], "headline"=>"Network", "cummulated"=>"false", "linegraph"=>"false"}]}, "CPU"=>{"y_scale"=>1, "y_label"=>"Percent", "single_graphs"=>[{"lines"=>[{"label"=>"Idle", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_id"=>"cpu-0+cpu-idle"}, {"label"=>"Used", "limits"=>{"max"=>"10", "min"=>"0"}, "metric_id"=>"cpu-0+cpu-user"}], "headline"=>"CPU", "cummulated"=>"false", "linegraph"=>"false"}]}, "Disk"=>{"y_scale"=>1073741824, "y_label"=>"GByte", "single_graphs"=>[{"lines"=>[{"label"=>"used", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_column"=>"used", "metric_id"=>"df+df-root"}, {"label"=>"free", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_column"=>"free", "metric_id"=>"df+df-root"}], "headline"=>"root", "cummulated"=>"true", "linegraph"=>"false"}]}, "Memory"=>{"y_scale"=>1048567, "y_label"=>"MByte", "single_graphs"=>[{"lines"=>[{"label"=>"Used", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_id"=>"memory+memory-used"}, {"label"=>"Free", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_id"=>"memory+memory-free"}, {"label"=>"Cached", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_id"=>"memory+memory-cached"}], "headline"=>"Memory", "cummulated"=>"true", "linegraph"=>"false"}]}}

  PARSE_CONFIG_3 ={"Network"=>{"y_scale"=>1, "y_label"=>"MByte", "single_graphs"=>[{"lines"=>[{"label"=>"received", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_column"=>"rx", "metric_id"=>"interface+if_packets-eth0"}, {"label"=>"sent", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_column"=>"tx", "metric_id"=>"interface+if_packets-eth0"}], "headline"=>"Network", "cummulated"=>"false", "linegraph"=>"false"}]}, "CPU"=>{"y_scale"=>1, "y_label"=>"Percent", "single_graphs"=>[{"lines"=>[{"label"=>"Idle", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_id"=>"cpu-0+cpu-idle"}, {"label"=>"Used", "limits"=>{"max"=>"10", "min"=>"0"}, "metric_id"=>"cpu-0+cpu-user"}], "headline"=>"CPU", "cummulated"=>"false", "linegraph"=>"false"}]}, "Disk"=>{"y_scale"=>1073741824, "y_label"=>"GByte", "single_graphs"=>[{"lines"=>[{"label"=>"used", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_column"=>"used", "metric_id"=>"df+df-root"}, {"label"=>"free", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_column"=>"free", "metric_id"=>"df+df-root"}], "headline"=>"root", "cummulated"=>"true", "linegraph"=>"false"}]}, "Memory"=>{"y_scale"=>1048567, "y_label"=>"MByte", "single_graphs"=>[{"lines"=>[{"label"=>"Used", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_id"=>"memory+memory-used"}, {"label"=>"Free", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_id"=>"memory+memory-free"}, {"label"=>"Cached", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_id"=>"memory+memory-cached"}], "headline"=>"Memory", "cummulated"=>"true", "linegraph"=>"false"}]}}

  def setup
    # standard setup
    Metric.stubs(:default_host).returns('waerden')
  end

  def test_not_running_collectd_while_generating_config
     Graph.stubs(:plugin_config_dir).returns("/notfound/")
     Metric.stubs(:find).with(:all).returns([])

    assert_raise ServiceNotRunning do
      ret = Graph.find(:all)
    end

  end

  def test_finders
    Graph.stubs(:parse_config).returns(PARSE_CONFIG_1)

    ret = Graph.find(:all)

    assert_equal 4, ret.size
    assert ret.map{|x| x.group_name}.include?('CPU')
    assert ret.map{|x| x.y_scale}.include?(1)
    assert ret.map{|x| x.y_label}.include?('Percent')
    
    ret = Graph.find('CPU')
    assert ret.y_scale == 1
    assert ret.y_label == 'Percent'

    ret = Graph.find('notfound')
    assert_equal 0, ret.size
  end

  def test_find_limits
    Graph.stubs(:parse_config).returns(PARSE_CONFIG_2)
    ret = Graph.find_limits('cpu-0+cpu-user')
    assert_equal 1, ret.size
    assert_equal [{"max"=>"10", "min"=>"0"}], ret

    ret = Graph.find_limits('cpu-0+cpu-user', 'CPU')
    assert_equal 1, ret.size
    assert_equal [{"max"=>"10", "min"=>"0"}], ret

    ret = Graph.find_limits('cpu-0+cpu-user', 'notfound')
    assert_equal 0, ret.size

    ret = Graph.find('notfound')
    assert_equal 0, ret.size
  end

  def test_check_limits_and_xml
    Graph.stubs(:parse_config).returns(PARSE_CONFIG_3)
    graph = Graph.find('CPU', true)

    graph.stubs(:read_data).with('waerden+cpu-0+cpu-idle').returns({ "value"=>
      {Time.at(1252071700) =>"6.1514301440e+01".to_f,
      Time.at(1252071690) =>"6.1518643200e+01".to_f,
      Time.at(1252071680) =>"6.1513154560e+01".to_f,
      Time.at(1252071780) => nil,
      Time.at(1252071670) =>"6.1510287360e+01".to_f,
      Time.at(1252071770) => nil,
      Time.at(1252071660) =>"6.1664133120e+01".to_f,
      Time.at(1252071750) =>"6.1545021440e+01".to_f,
      Time.at(1252071760) =>"6.1678837760e+01".to_f},
      
      "interval" => 10,
      "starttime" => Time.at(1252071660) })
    
    graph.stubs(:read_data).with('waerden+cpu-0+cpu-user').returns({ "value"=>
      {Time.at(1252071700) =>"6.1514301440e+01".to_f,
      Time.at(1252071690) =>"6.1518643200e+01".to_f,
      Time.at(1252071680) =>"6.1513154560e+01".to_f,
      Time.at(1252071780) => nil,
      Time.at(1252071670) =>"6.1510287360e+01".to_f,
      Time.at(1252071770) => nil,
      Time.at(1252071660) =>"6.1664133120e+01".to_f,
      Time.at(1252071750) =>"6.1545021440e+01".to_f,
      Time.at(1252071760) =>"6.1678837760e+01".to_f},
      
      "interval" => 10,
      "starttime" => Time.at(1252071660) })


    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.graph do
      xml.id "CPU"
      xml.y_scale 1
      xml.y_label "Percent"
      xml.y_max nil
      xml.y_decimal_places nil
      xml.single_graphs(:type => :array) do
        xml.single_graph do
          xml.cummulated false
          xml.linegraph false
          xml.headline "CPU"
          xml.lines(:type => :array)do
            xml.line do
              xml.metric_id "cpu-0+cpu-idle"
              xml.label "Idle"
              xml.limits do
                xml.max 0
                xml.min 0
                xml.reached false
              end
            end        
            xml.line do
              xml.metric_id "cpu-0+cpu-user"
              xml.label "Used"
              xml.limits do
                xml.max 10
                xml.min 0
                xml.reached true
              end
            end        
          end
        end
      end
    end

    graph_xml = graph.to_xml(:checklimits => true)
#    puts "   #{graph_xml.inspect}"
    should_xml = xml.target!
#    puts "   #{should_xml.inspect}"    
    assert xml_cmp graph_xml, should_xml

  end
  
  
end
