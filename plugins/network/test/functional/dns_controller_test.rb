require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
#require 'dns'
require 'rubygems'
require 'mocha'
require File.expand_path( File.join("test","plugin_basic_tests"), RailsParent.parent )

class DnsControllerTest < ActionController::TestCase

  def setup
    @model_class = DNS
    DNS.stubs(:find).returns(DNS.new({"dnsdomains" => ["d1", "d2"], "dnsservers" => ["s1", "s2"]}))
    @controller = Network::DnsController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
  end  

  def test_content_of_xml
    get :show, :format => 'xml'
    h = Hash.from_xml @response.body
    assert_instance_of Array, h['dns']['nameservers']
    assert_instance_of Array, h['dns']['searches']
  end

  include PluginBasicTests

end

