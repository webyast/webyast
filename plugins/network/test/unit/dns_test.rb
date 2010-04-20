require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class DNSTest < ActiveSupport::TestCase

   RESPONSE_FULL = {
		   'interfaces'=>{
                                'eth0'=>{'bootproto'=>'dhcp'},
                                'eth1'=>{'bootproto'=>'static', 'ipaddr'=>'192.168.3.27/24'}},
                   'routes'=>{'default'=>{'via'=>'10.20.7.254'}},
                   'dns'=>{'nameservers'=>['10.20.0.15','10.20.0.8'], 'searches'=>['suse.cz','suse.de']},
                   'hostname'=>{'name'=>'linux', 'domain'=>'suse.cz'}
   }

 def setup
   YastService.stubs(:Call).with("YaPI::NETWORK::Read").returns(RESPONSE_FULL)
 end

 def test_index
   dns = DNS.find
   assert_instance_of Array, dns.searches
   assert_instance_of Array, dns.nameservers
 end

 def test_validations
   dns = DNS.find
   assert dns.valid?
   dns.nameservers = ["<danger script>"]
   assert dns.invalid?
   dns.nameservers = ["10.20.4.15"]
   assert dns.valid?
   dns.searches = [ "<danger script>" ]
   assert dns.invalid?
   dns.searches = ["local.com"]
   assert dns.valid?
 end

end

