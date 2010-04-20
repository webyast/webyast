require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class HostnameTest < ActiveSupport::TestCase

   RESPONSE_FULL = {
		   'interfaces'=>{
                                'eth0'=>{'bootproto'=>'dhcp'},
                                'eth1'=>{'bootproto'=>'static', 'ipaddr'=>'192.168.3.27/24'}},
                   'routes'=>{'default'=>'10.20.7.254'},
                   'dns'=>{'dnsservers'=>'10.20.0.15 10.20.0.8', 'dnsdomains'=>'suse.cz suse.de'},
                   'hostname'=>{'name'=>'linux', 'domain'=>'suse.cz'}
   }

 def setup
   YastService.stubs(:Call).with("YaPI::NETWORK::Read").returns(RESPONSE_FULL)
 end

 def test_getter
   hostname=Hostname.find
   assert_equal("linux", hostname.name)
   assert_equal("suse.cz", hostname.domain)
 end

 def test_validations
   hostname=Hostname.find
   assert hostname.valid?
   hostname.name = nil
   assert hostname.valid?
   hostname.domain = "<script>"
   assert hostname.invalid?
   hostname.domain = "local"
   assert hostname.valid?
 end
 
end

