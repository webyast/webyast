require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'scr'
require 'mocha'
require 'status'

class StatusTest < ActiveSupport::TestCase
  def setup
    # http://railsforum.com/viewtopic.php?id=1719
    Status.any_instance.stubs(:datapath).returns("/var/lib/collectd/test")
    Status.any_instance.stubs(:check_collectd).returns(true)
  end

  def test_set_datapath
    status = Status.new
    assert (status.datapath = "/var/lib/collectd/test/"),  "/var/lib/collectd/test"
    status = Status.new
    assert_equal (status.datapath = "/test/foo.bar"), "/test/foo.bar"
  end

  def test_set_datapath_default
    Scr.instance.stubs(:execute).with(["/usr/sbin/collectd"]).returns(nil)

    IO.stubs(:popen).with("hostname").returns(String) #FIXME: replace String with IO
    IO.stubs(:popen).with("domainname").returns(String) # returns(IO.new(2, "r+")) dont work
    IO.stubs(:popen).with("ls /var/lib/collectd/").returns(String) # because of missing EOF token
    String.stubs(:read).with(nil).returns("test")
    String.stubs(:close).with(nil).returns(nil)

    # test that datapath is initialized correctly
    Dir.stubs(:glob).returns(["/var/lib/collectd/test","/var/lib/collectd/test2"])
    status = Status.new
    assert_equal "/var/lib/collectd/test", status.datapath
  end

  def test_available_metrics
    Scr.instance.stubs(:execute).with(["/usr/sbin/collectd"]).returns(nil)
    status = Status.new

    # simulate environment
    status.stubs(:metric_types).returns(['cpu', 'memory'])
    status.stubs(:metric_files).with('cpu').returns(['/var/lib/collectd/test/cpu/cpuheat.rrd'])
    status.stubs(:metric_files).with('memory').returns(['/var/lib/collectd/test/memory/memory.rrd'])

    status.datapath = "/var/lib/collectd"
    fake_metrics = {"memory"=>{:rrds=>["/var/lib/collectd/test/memory/memory.rrd"]},
      "cpu"=>{:rrds=>["/var/lib/collectd/test/cpu/cpuheat.rrd"]}}
    assert_equal fake_metrics, status.available_metrics
  end

  def test_collect_data

  end

  def test_fetch_data
    Scr.instance.stubs(:execute).with(["/usr/sbin/collectd"]).returns(nil)
    stop = Time.now
    start = Time.now - 300

    status = Status.new

    rrd_output = <<EOF
                             rx                  tx

1248092090: nan nan
1248092160: nan nan
1248092230: nan nan
1248092300: 2.4628571429e+01 4.0500000000e+00
1248092370: 4.7314285714e+01 2.1435714286e+01
1248092440: 5.7578571429e+01 4.0992857143e+01
1248092510: 4.9271428571e+01 3.4264285714e+01
1248092580: 7.7485714286e+01 4.3878571429e+01
1248092650: 1.1698571429e+02 9.7942857143e+01
1248092720: 2.3042857143e+01 2.9928571429e+00
1248092790: 2.2585714286e+01 4.0714285714e+00
1248092860: 2.4292857143e+01 2.4142857143e+00
1248092930: 2.5092857143e+01 2.8285714286e+00
1248093000: 3.1314285714e+01 1.5542857143e+01
1248093070: 2.3064285714e+01 2.7071428571e+00
1248093140: nan nan
EOF

    # stub the command output
    status.stubs(:run_rrdtool).with("/var/lib/collectd/test/memory-free.rrd", start, stop).returns(rrd_output)

    status.datapath = "/test"

    expected_response = {"tx"=>
  {"1248092580"=>"4.3878571429e+01",
   "1248093140"=>"invalid",
   "1248092790"=>"4.0714285714e+00",
   "1248092230"=>"invalid",
   "1248092440"=>"4.0992857143e+01",
   "1248093000"=>"1.5542857143e+01",
   "1248092650"=>"9.7942857143e+01",
   "1248092860"=>"2.4142857143e+00",
   "1248092090"=>"invalid",
   "1248092300"=>"4.0500000000e+00",
   "1248092510"=>"3.4264285714e+01",
   "1248093070"=>"2.7071428571e+00",
   "1248092720"=>"2.9928571429e+00",
   "1248092930"=>"2.8285714286e+00",
   "1248092160"=>"invalid",
   "1248092370"=>"2.1435714286e+01"},
 "rx"=>
  {"1248092580"=>"7.7485714286e+01",
   "1248093140"=>"invalid",
   "1248092790"=>"2.2585714286e+01",
   "1248092230"=>"invalid",
   "1248092440"=>"5.7578571429e+01",
   "1248093000"=>"3.1314285714e+01",
   "1248092650"=>"1.1698571429e+02",
   "1248092860"=>"2.4292857143e+01",
   "1248092090"=>"invalid",
   "1248092300"=>"2.4628571429e+01",
   "1248092510"=>"4.9271428571e+01",
   "1248093070"=>"2.3064285714e+01",
   "1248092720"=>"2.3042857143e+01",
   "1248092930"=>"2.5092857143e+01",
   "1248092160"=>"invalid",
   "1248092370"=>"4.7314285714e+01"},
 "interval"=>70,
 "starttime"=>1248092090}

    assert_equal expected_response, status.fetch_metric("/var/lib/collectd/test/memory-free.rrd", start, stop)
  end
end
