#--
# Copyright (c) 2009 Novell, Inc.
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

class InterfaceTest < ActiveSupport::TestCase

   RESPONSE_FULL = {
		   'interfaces'=>{
                'eth0'=>{'bootproto'=>'dhcp', 'vendor'=>'vendor0'},
                'eth1'=>{'bootproto'=>'static', 'vendor'=>'vendor1', 'ipaddr'=>'1.2.3.4/24'},
                'vlan0'=>{'bootproto'=>'dhcp', 'vlan_id'=>'1', 'vlan_etherdevice' =>'eth0'},
                'br0'=>{'bootproto'=>'none', 'bridge_ports'=>'vlan0 eth0'},
                'bond0'=>{'bond_miimon'=>'miimon=100', 'bootproto'=>'none', 'bond_mode'=>'mode=balance-alb', 'bond_slaves'=>['vlan0', 'eth0']}},
                
           'routes'=>{'default'=>{'via'=>'10.20.7.254'}},
           'dns'=>{'dnsservers'=>'10.20.0.15 10.20.0.8', 'dnsdomains'=>'suse.cz suse.de'},
           'hostname'=>{'name'=>'linux', 'domain'=>'suse.cz'}
   }
   


 def setup
   YastService.stubs(:Call).with("YaPI::NETWORK::Read").returns(RESPONSE_FULL)
 end

 def test_getter1
   iface=Interface.find('eth0')
   assert_equal 'dhcp', iface.bootproto
   assert_equal 'vendor0', iface.vendor
   assert_equal 'eth0', iface.id
 end
 
 def test_getter2
   iface=Interface.find('eth1')
   assert_equal 'static', iface.bootproto
   assert_equal '1.2.3.4/24', iface.ipaddr
   assert_equal 'vendor1', iface.vendor
   assert_equal 'eth1', iface.id
 end

 def test_validations
   iface = Interface.find('eth1')
   assert iface.valid?
   iface.bootproto = "dhcp6"
   assert iface.invalid?
   iface.bootproto = "static"
   iface.id = "<script malicious>"
   assert iface.invalid?
   iface.id = "eth1"
   iface.ipaddr = "<malicious>"
   assert iface.invalid?
 end
 
 def test_vlan
   iface=Interface.find('vlan0')
   assert_equal 'dhcp', iface.bootproto
   assert_equal '1', iface.vlan_id
   assert_equal 'eth0', iface.vlan_etherdevice
   assert_equal 'vlan0', iface.id
 end
 
 def test_bridge
   iface=Interface.find('br0')
   assert_equal 'none', iface.bootproto
   assert_equal 2, iface.bridge_ports.split(" ").count
   assert iface.bridge_ports.split(" ").include?('vlan0')
   assert_equal 'br0', iface.id   
 end
 
  def test_bond
   iface=Interface.find('bond0')
   assert_equal 'none', iface.bootproto
   assert_equal 'mode=balance-alb', iface.bond_mode
   assert_equal 'miimon=100', iface.bond_miimon
   assert_equal 2, iface.bond_slaves.count
   assert_equal 'bond0', iface.id
 end

 def test_netmask
   YastService.stubs(:Call).with("YaPI::NETWORK::Write",  {'interface' => ['a{sa{ss}}', {'eth7' => {'bootproto' => 'static', 'ipaddr' => '1.1.1.1/255.255.255.255'}}]}).returns true
   iface = Interface.new "id" => "eth7", "bootproto" => "static", "ipaddr" => "1.1.1.1/255.255.255.255", "type" => "eth"
   iface.save!
 end
end

