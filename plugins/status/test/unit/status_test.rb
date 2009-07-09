require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'scr'
require 'mocha'
require 'test_helper'

class StatusTest < ActiveSupport::TestCase
  def setup
    # http://railsforum.com/viewtopic.php?id=1719
  end

  def test_set_datapath
    Scr.instance.stubs(:execute).with(["collectd"]).returns(nil)

    status = Status.new()
    assert status.set_datapath("/var/lib/collectd/test/"), "/var/lib/collectd/test"
    status = Status.new()
    assert_equal status.set_datapath("/test/foo.bar"), "/test/foo.bar"
  end

  def test_set_datapath_default
    Scr.instance.stubs(:execute).with(["collectd"]).returns(nil)
    IO.stubs(:popen).with("hostname").returns(String) #FIXME: replace String with IO
    IO.stubs(:popen).with("domainname").returns(String) # returns(IO.new(2, "r+")) dont work
    IO.stubs(:popen).with("ls /var/lib/collectd/").returns(String) # because of missing EOF token
    String.stubs(:read).with(nil).returns("test")
    String.stubs(:close).with(nil).returns(nil)

    status = Status.new()
    assert_equal status.set_datapath(), "/var/lib/collectd/test"
  end

  def test_available_metrics
    Scr.instance.stubs(:execute).with(["collectd"]).returns(nil)

# stubs(:set_datapath)

    IO.stubs(:popen).with("ls /var/lib/collectd").returns(String) #FIXME: replace String with IO
    IO.stubs(:popen).with("ls /var/lib/collectd/cpu").returns(String)
    IO.stubs(:popen).with("ls /var/lib/collectd/memory").returns(String)
    String.stubs(:read).with(nil).returns("cpu memory")
    String.stubs(:close).with(nil).returns(nil)

    status = Status.new()
    status.datapath = "/var/lib/collectd"
    assert_equal status.available_metrics, {"memory"=>{:rrds=>[]}, "cpu"=>{:rrds=>[]}}
#{"memory"=>{:rrds=>["cpu", "memory"]}, "cpu"=>{:rrds=>["cpu", "memory"]}}
  end

  def test_collect_data

  end

  def test_fetch_data
    Scr.instance.stubs(:execute).with(["collectd"]).returns(nil)
    IO.stubs(:popen).with("rrdtool fetch /test/memory-free.rrd AVERAGE --start #{Time.now.strftime("%H:%M,%m/%d/%Y")} --stop #{Time.now.strftime("%H:%M,%m/%d/%Y")}").returns(String)
    String.stubs(:read).with(nil).returns("               value\n\n1247156690: nan\n1247156700: nan\n1247156710: nan\n")
    String.stubs(:close).with(nil).returns(nil)

    status = Status.new()
    status.datapath = "/test"
    assert_equal status.fetch_data("memory-free.rrd"), {"memory-free" => {"value" => \
            {"T_1247156690" => "nan", "T_1247156700" => "nan", "T_1247156710" => "nan"}}}
  end
end
