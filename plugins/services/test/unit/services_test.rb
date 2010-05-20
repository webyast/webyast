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

require 'service'

class ServiceTest < ActiveSupport::TestCase

YAML_CONTENT = <<EOF
services:
  - acpid
  - dbus
  - my_app
EOF

  def setup    
    Paths.const_set 'CONFIG', File.join(File.dirname(__FILE__),"..","..","test","etc")
    YaST::ConfigFile.any_instance.stubs(:path).returns(__FILE__)
    YaST::ConfigFile.stubs(:read_file).returns(YAML_CONTENT)
    @read_args = {
	'read_status'		=> [ 'b', false],
	'description'		=> ['b', true],
	'shortdescription' 	=> ['b', true],
	'dependencies'		=> [ 'b', true],
	'filter'		=> [ 'as', ['acpid', 'dbus','my_app']]
    }
    @custom_args = {
	'read_status'		=> [ 'b', false],
	'description'		=> ['b', true],
	'shortdescription'	=> ['b', true],
	'filter'		=> [ 'as', ['acpid', 'dbus','my_app']],
	'dependencies'		=> [ 'b', false],
	'custom'		=> ['b', true]
    }
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
    YastService.stubs(:Call).with('YaPI::SERVICES::Read', @read_args).returns([])
    YastService.stubs(:Call).with('YaPI::SERVICES::Read', @custom_args).returns([])

    ret = Service.find_all(nil)
    assert ret == []
  end

  test "check find LSB service" do
    srv = [{"name" => "acpid"}, {"name" => "dbus", "description" => "DBUS service description"}]
    custom = [{"name" => "my_app", "description" => "My application long description", "shortdescription" => "summary"}]
  
    YastService.stubs(:Call).with('YaPI::SERVICES::Read', @read_args).returns(srv)
    YastService.stubs(:Call).with('YaPI::SERVICES::Read', @custom_args).returns(custom)

    ret = Service.find_all(Hash.new)
    assert ret.map {|s| s.name} == ['acpid', 'dbus', 'my_app']
    ret.each do |s|
	assert !s.description.nil?
	assert !s.summary.nil?
    end
    assert !ret[0].custom
    assert ret[2].custom # my_app is custom
  end

  test "check missing LSB service" do
    ret = {"exit" => "127", "stderr" => "", "stdout" => "sh: line 1: /etc/init.d/non_existing_service: No such file or directory\n"}
    YastService.stubs(:Call).with('YaPI::SERVICES::Execute', {"name" => [ "s", "non_existing_service" ], "action" => [ "s", "status"], 'custom' => ['b', false]}).returns(ret)

    s = Service.new('non_existing_service')
    assert s.save({"execute" => 'status'}) == ret
  end

  test "check LSB service status" do
    ret = [{'name' => 'ntp', 'status' => '0'}]
    YastService.stubs(:Call).with('YaPI::SERVICES::Read', {'service' => [ 's', 'ntp' ], 'custom' => ['b', false]}).returns(ret)

    s = Service.new('ntp')
    s.read_status({})
    assert s.status == '0'
  end

  test "check custom service status" do
    ret = [{'name' => 'my_app', 'status' => '255'}]
    YastService.stubs(:Call).with('YaPI::SERVICES::Read', {'service' => [ 's', 'my_app' ], 'custom' => ['b', true]}).returns(ret)

    s = Service.new('my_app')
    s.read_status({"custom" => "true"})
    assert s.status == '255'
  end

  test "check service filtering" do
    srv = [
	{"name" => "dbus", "description" => "DBUS service description", "required_for_stop" => [ "network", "nfs", "my_app"] },
	{"name" => "network", "description" => "network service description", "required_for_start" => [ "dbus"] }
    ]
    custom = [{"name" => "my_app" } ]
  
    YastService.stubs(:Call).with('YaPI::SERVICES::Read', @read_args).returns(srv)
    YastService.stubs(:Call).with('YaPI::SERVICES::Read', @custom_args).returns(custom)

    ret = Service.find_all(Hash.new)
    assert ret.map {|s| s.name} == ['dbus', 'my_app'] # network filtered out
    assert ret[0].required_for_stop == [ "my_app" ] # network, nfs filtered out
  end

  test "restart service" do
    ret = {"exit" => "0", "stderr" => "", "stdout" => "restarted"}
    # because of restart, extra parameters were added:
    YastService.stubs(:Call).with('YaPI::SERVICES::Execute', {
	"name" => [ "s", "dbus" ],
	"action" => [ "s", "restart"],
	'custom' => ['b', false],
	'only_execute' => ['b', true]
    }).returns(ret)

    s = Service.new('dbus')
    assert s.save({"execute" => 'restart'}) == ret
  end

  test "stop service" do
    ret = {"exit" => "0", "stderr" => "", "stdout" => "stopped"}
    # because of restart, extra parameters were added:
    YastService.stubs(:Call).with('YaPI::SERVICES::Execute', {
	"name" => [ "s", "dbus" ],
	"action" => [ "s", "stop"],
	'custom' => ['b', false]
    }).returns(ret)

    s = Service.new('dbus')
    assert s.save({"execute" => 'stop'}) == ret
  end

end
