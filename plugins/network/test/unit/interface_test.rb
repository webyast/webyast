require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class InterfaceTest < ActiveSupport::TestCase

   RESPONSE_FULL = {
		   'interfaces'=>{
                                'eth0'=>{'bootproto'=>'dhcp'},
                                'eth1'=>{'bootproto'=>'static', 'ipaddr'=>'1.2.3.4/24'}},
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
 end
 
 def test_getter2
   iface=Interface.find('eth1')
   assert_equal 'static', iface.bootproto
   assert_equal '1.2.3.4/24', iface.ipaddr
 end

end

