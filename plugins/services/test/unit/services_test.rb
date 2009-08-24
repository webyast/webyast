require 'test_helper'

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

  test "find_all nil parameter" do
    Service.stubs(:run_runlevel).returns("N 5")
    YastService.stubs(:Call).with('YaPI::SERVICES::Read', {"runlevel" => [ "i", 5 ], "read_status" => [ "b", false]}).returns([])

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
    YastService.stubs(:Call).with('YaPI::SERVICES::Read', {"runlevel" => [ "i", 5 ], "read_status" => [ "b", false]}).returns(srv)

    ret = Service.find_all(Hash.new)
    assert ret.map {|s| s.name} == ['acpid', 'dbus']
  end


  test "find custom service" do
# TODO
  end

  test "check invalid custom service" do
# TODO
  end

  test "missing command is custom service" do
# TODO
  end

  test "check missing LSB service" do
    ret = {"exit" => "127", "stderr" => "", "stdout" => "sh: line 1: /etc/init.d/non_existing_service: No such file or directory\n"}
    YastService.stubs(:Call).with('YaPI::SERVICES::Execute', 'non_existing_service', 'status').returns(ret)

    s = Service.new('non_existing_service')
    assert s.save('status') == ret
  end

  test "check LSB service status" do
    ret = {:exit => 0}
    YastService.stubs(:Call).with('YaPI::SERVICES::Execute', 'ntp', 'status').returns(ret)

    s = Service.new('ntp')
    assert s.save('status') == ret
  end

  test "check custom service status" do
  end


end
