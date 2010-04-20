require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class RouteTest < ActiveSupport::TestCase

   RESPONSE_FULL = {
		   'interfaces'=>{
                                'eth0'=>{'bootproto'=>'dhcp'},
                                'eth1'=>{'bootproto'=>'static', 'ipaddr'=>'192.168.3.27/24'}},
                   'routes'=>{'default'=>{'via'=>'10.20.7.254'}},
                   'dns'=>{'dnsservers'=>'10.20.0.15 10.20.0.8', 'dnsdomains'=>'suse.cz suse.de'},
                   'hostname'=>{'name'=>'linux', 'domain'=>'suse.cz'}
   }

 def setup
   YastService.stubs(:Call).with("YaPI::NETWORK::Read").returns(RESPONSE_FULL)
 end

 def test_getter
   route=Route.find('default')
   assert_equal '10.20.7.254', route.via
   assert_equal 'default', route.id
 end
 
 def test_index
   routes = Route.find(:all)
   assert_instance_of Hash, routes
   route = routes["default"]
   assert_equal 'default', route.id
 end

 def test_validations
   route=Route.find('default')
   assert route.valid?
   route.id = "10.10/24"
   assert route.valid?
   route.id = "| rm -rf /"
   assert route.invalid?
   route.id = "default"
   route.via = "<malicaious>"
   assert route.invalid?
 end

 #FIXME: test for YaPI::NETWORK::Write with invalid IP of default route

 
end

