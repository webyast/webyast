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
    YastService.stubs(:Call).with('YaPI::SERVICES::Read', {
	"runlevel" => [ "i", 5 ],
	"read_status" => [ "b", false],
	'description' => ['b', true],
	'custom' => ['b', false]}).returns([])

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
    srv = [{"name" => "acpid"}, {"name" => "dbus", "description" => "DBUS service description"}]
  
    Service.stubs(:run_runlevel).returns("N 5")
    YastService.stubs(:Call).with('YaPI::SERVICES::Read', {
	"runlevel" => [ "i", 5 ],
	"read_status" => [ "b", false],
	'description' => ['b', true],
	'custom' => ['b', false]}).returns(srv)

    ret = Service.find_all(Hash.new)
    assert ret.map {|s| s.name} == ['acpid', 'dbus']
    ret.each do |s|
	assert !s.description.nil?
    end
  end

  test "check missing LSB service" do
    ret = {"exit" => "127", "stderr" => "", "stdout" => "sh: line 1: /etc/init.d/non_existing_service: No such file or directory\n"}
    YastService.stubs(:Call).with('YaPI::SERVICES::Execute', {"name" => [ "s", "non_existing_service" ], "action" => [ "s", "status"], 'custom' => ['b', false]}).returns(ret)

    s = Service.new('non_existing_service')
    assert s.save({"execute" => 'status'}) == ret
  end

  test "check LSB service status" do
    ret = [{"name" => "ntp", "status" => "0"}]
    YastService.stubs(:Call).with('YaPI::SERVICES::Read', {"service" => [ "s", "ntp" ], 'custom' => ['b', false]}).returns(ret)

    s = Service.new('ntp')
    s.read_status({})
    assert s.status == '0'
  end


end
