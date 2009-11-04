require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

require 'service'

class ServiceTest < ActiveSupport::TestCase

  def setup    
  end

  test "read current runlevel" do
    Service.stubs(:run_runlevel).returns("N 5")

    assert Service.current_runlevel == 5
  end

  test "test uknown current runlevel" do
    Service.stubs(:run_runlevel).returns("unknown")

    assert_raise Exception do
	Service.current_runlevel
    end
  end

  test "test S runlevel" do
    Service.stubs(:run_runlevel).returns("N S")

    assert Service.current_runlevel == -1
  end

  test "find_all nil parameter" do
    Service.stubs(:run_runlevel).returns("N 5")
    YastService.stubs(:Call).with('YaPI::SERVICES::Read', {"runlevel" => [ "i", 5 ], "read_status" => [ "b", false], 'custom' => ['b', false]}).returns([])

    ret = Service.find_all(nil)
    assert ret == []
  end

  test "find all in unknown current runlevel" do
    Service.stubs(:run_runlevel).returns("unknown")

    assert_raise Exception do
	Service.find_all(nil)
    end
  end

  test "check find LSB service" do
    srv = [{"name" => "acpid"}, {"name" => "dbus"}]
  
    Service.stubs(:run_runlevel).returns("N 5")
    YastService.stubs(:Call).with('YaPI::SERVICES::Read', {"runlevel" => [ "i", 5 ], "read_status" => [ "b", false], 'custom' => ['b', false]}).returns(srv)

    ret = Service.find_all(Hash.new)
    assert ret.map {|s| s.name} == ['acpid', 'dbus']
  end

#  test "find custom service" do
#    Service.stubs(:run_runlevel).returns("N 5")
#    YaST::ConfigFile.stubs(:config_default_location).returns(vendor_config('valid'))
#
#    ret = Service.find_all({"custom" => true})
#    assert ret.map {|s| s.name} == ['vendor_service']
#  end
#
#  test "missing custom service" do
#    Service.stubs(:run_runlevel).returns("N 5")
#    YaST::ConfigFile.stubs(:config_default_location).returns(vendor_config('missing'))
#    YastService.stubs(:Call).returns({})
#
#    ret = Service.find_all({"custom" => true})
#    assert ret.map {|s| s.name} == []
#  end
#
#  test "missing command in custom service" do
#    YaST::ConfigFile.stubs(:config_default_location).returns(vendor_config('invalid'))
#    YastService.stubs(:Call).returns({})
#
#    s = Service.new('vendor_service')
#    assert_raise Exception do
#	s.save('status')
#    end
#  end

  test "check missing LSB service" do
    ret = {"exit" => "127", "stderr" => "", "stdout" => "sh: line 1: /etc/init.d/non_existing_service: No such file or directory\n"}
    YastService.stubs(:Call).with('YaPI::SERVICES::Execute', {"name" => [ "s", "non_existing_service" ], "action" => [ "s", "status"], 'custom' => ['b', false]}).returns(ret)

    s = Service.new('non_existing_service')
    assert s.save({"execute" => 'status'}) == ret
  end

  test "check LSB service status" do
    ret = {'exit' => '0'}
    YastService.stubs(:Call).with('YaPI::SERVICES::Execute', {"name" => [ "s", "ntp" ], "action" => [ "s", "status"], 'custom' => ['b', false]}).returns(ret)

    s = Service.new('ntp')
    assert s.save({"execute" => 'status'}) == ret
    s.read_status({})
    assert s.status == '0'
  end


#  test "check custom service status" do
#    YaST::ConfigFile.stubs(:config_default_location).returns(vendor_config('valid'))
#
#    # do not call introspection in the Scr constructor
#    DBus::SystemBus.instance.stubs(:introspect).returns('<node><interface name="org.opensuse.yast.SCR.Methods"></interface></node>')
#
#    ret = {'exit' => '0', 'stderr' => '', 'stdout' => "Checking for service collectd ..running\n"}
#    Scr.instance.stubs(:execute).with(['/usr/sbin/rccollectd status']).returns(ret)
#
#    s = Service.new('vendor_service')
#    assert s.save("status") == ret
#    s.read_status
#    assert s.status == '0'
#  end


end
