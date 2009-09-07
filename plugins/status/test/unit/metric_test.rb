require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'scr'
require 'mocha'
require 'metric'
require 'test_helper'

def test_data(name)
  File.join(File.dirname(__FILE__), '..', 'data', name)
end

class MetricTest < ActiveSupport::TestCase

  def setup
    # standard setup
    Metric.stubs(:this_hostname).returns('myhost.domain.de')
    Metric.stubs(:available_hosts).returns(['foo.com', 'myhost.domain.de'])
    Metric.stubs(:rrd_files).returns(['/var/lib/collectd/foo.com/cpu-0/cppudata-1.rrd', '/var/lib/collectd/myhost.domain.de/memory/memory-free.rrd', '/var/lib/collectd/myhost.domain.de/cpu-1/cpudata-1.rrd', '/var/lib/collectd/myhost.domain.de/cpu-1/cpudata-2.rrd', '/var/lib/collectd/myhost.domain.de/cpu-2/cpudata-1.rrd', '/var/lib/collectd/myhost.domain.de/interface/packets.rrd', '/var/lib/collectd/myhost.domain.de/interface/some-0.rrd'])
  end

  def teardown
  end
  
  def test_default_host
    # if only one host data is available, then that one should be
    # the one used for the data directory
    Metric.stubs(:this_hostname).returns(nil)
    assert_equal 'foo.com', Metric.default_host
    
    Metric.stubs(:this_hostname).returns('myhost.domain.de')
    assert_equal 'myhost.domain.de', Metric.default_host
  end

  def test_parse_rrdtool_output
    stop = Time.now
    start = Time.now - 300

    Metric.stubs(:run_rrdtool).with('/var/lib/collectd/myhost.domain.de/memory/memory-free.rrd', :start => start, :stop => stop).returns(File.open(test_data('rrdtool-memory-free.txt')).read)
    Metric.stubs(:run_rrdtool).with('/var/lib/collectd/myhost.domain.de/interface/packets.rrd', :start => start, :stop => stop).returns(File.open(test_data('rrdtool-packets.txt')).read)

    ret = Metric.find(:all, :plugin => /memory/, :type => 'memory', :type_instance => 'free')
    memory = ret.first

    expected = { "value"=>
      {"1252071700"=>"6.1514301440e+08",
      "1252071690"=>"6.1518643200e+08",
      "1252071680"=>"6.1513154560e+08",
      "1252071780"=>"invalid",
      "1252071670"=>"6.1510287360e+08",
      "1252071770"=>"invalid",
      "1252071660"=>"6.1664133120e+08",
      "1252071760"=>"6.1678837760e+08",
      "1252071750"=>"6.1545021440e+08"},
      "interval"=>10,
      "starttime"=>1252071660 }
    
    assert_equal expected, memory.data(:start => start, :stop => stop)

    ret = Metric.find(:all, :plugin => /interface/, :type => 'packets')
    packets = ret.first
    expected =  {"tx"=>
     {"1252075780"=>"4.2576000000e+02",
      "1252075770"=>"1.5922000000e+02",
      "1252075760"=>"6.1660000000e+01",
      "1252075500"=>"7.7900000000e+00",
      "1252075800"=>"invalid",
      "1252075790"=>"invalid"},
    "rx"=>
     {"1252075780"=>"2.8069000000e+02",
      "1252075770"=>"3.3962000000e+02",
      "1252075760"=>"2.5814000000e+02",
      "1252075500"=>"2.2150000000e+01",
      "1252075800"=>"invalid",
      "1252075790"=>"invalid"},
      "interval"=>260,
      "starttime"=>1252075500}
    
    assert_equal expected, packets.data(:start => start, :stop => stop)    
    
  end
  
  def test_collectd_running
    Scr.instance.stubs(:execute).with(['/usr/sbin/rccollectd', 'status']).returns({:exit => 0})
    assert Metric.collectd_running?
    Scr.instance.stubs(:execute).with(['/usr/sbin/rccollectd', 'status']).returns({:exit => 1})
    assert !Metric.collectd_running?
  end

  def test_finders
    ret = Metric.find(:all)
    assert_equal 7, ret.size
    assert ret.map{|x| x.plugin_full}.include?('cpu-1')
    assert ret.map{|x| x.plugin}.include?('memory')
    assert ret.map{|x| x.plugin}.include?('interface')
    
    ret = Metric.find(:all, :plugin => 'memory')
    assert_equal 1, ret.size
    assert_equal 'memory', ret.first.plugin
    assert_equal 'memory-free', ret.first.type_full
    assert_equal 'myhost.domain.de', ret.first.host

    # should produce same result
    ret = Metric.find(:all, :plugin_full => /memory/)
    assert_equal 1, ret.size
    ret = Metric.find(:all, :plugin_full => /memory/, :type_full => 'boooh')
    assert_equal 0, ret.size
    ret = Metric.find(:all, :plugin_full => /memory/, :type_full => 'memory-free')
    assert_equal 1, ret.size
    
    # test attributes
    assert_equal '/var/lib/collectd/myhost.domain.de/memory/memory-free.rrd', ret.first.path
    assert_equal 'myhost.domain.de/memory/memory-free', ret.first.id
    
    ret = Metric.find(:all, :plugin_full => /meemory/)
    assert_equal 0, ret.size

    ret = Metric.find(:all, :plugin_full => 'meemory')
    assert_equal 0, ret.size

    # using a regexp
    ret = Metric.find(:all, :plugin_full => /cpu/)
    assert ret.map{ |x| x.plugin_full }.include?('cpu-1')
    assert ret.map{ |x| x.plugin_full }.include?('cpu-2')
    assert ret.map{ |x| x.type_full }.include?('cpudata-1')
    assert ret.map{ |x| x.type_full }.include?('cpudata-2')
    assert_equal 3, ret.size
  end
  
  
end
