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

  def setup
    # standard setup
    Metric.stubs(:default_host).returns('waerden')
    Graph.stubs(:parse_config).returns({"Network"=>{"y_scale"=>1, "y_label"=>"MByte", "single_graphs"=>[{"lines"=>[{"label"=>"received", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_column"=>"rx", "metric_id"=>"interface+if_packets-eth0"}, {"label"=>"sent", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_column"=>"tx", "metric_id"=>"interface+if_packets-eth0"}], "headline"=>"Network", "cummulated"=>"false"}]}, "CPU"=>{"y_scale"=>1, "y_label"=>"Percent", "single_graphs"=>[{"lines"=>[{"label"=>"Idle", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_id"=>"cpu-0+cpu-idle"}, {"label"=>"Used", "limits"=>{"max"=>"10", "min"=>"0"}, "metric_id"=>"cpu-0+cpu-user"}], "headline"=>"CPU", "cummulated"=>"false"}]}, "Disk"=>{"y_scale"=>1073741824, "y_label"=>"GByte", "single_graphs"=>[{"lines"=>[{"label"=>"used", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_column"=>"used", "metric_id"=>"df+df-root"}, {"label"=>"free", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_column"=>"free", "metric_id"=>"df+df-root"}], "headline"=>"root", "cummulated"=>"true"}]}, "Memory"=>{"y_scale"=>1048567, "y_label"=>"MByte", "single_graphs"=>[{"lines"=>[{"label"=>"Used", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_id"=>"memory+memory-used"}, {"label"=>"Free", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_id"=>"memory+memory-free"}, {"label"=>"Cached", "limits"=>{"max"=>"0", "min"=>"0"}, "metric_id"=>"memory+memory-cached"}], "headline"=>"Memory", "cummulated"=>"true"}]}})

  end

  def test_finders
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
      xml.single_graphs(:type => :array) do
        xml.single_graph do
          xml.cummulated false
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
