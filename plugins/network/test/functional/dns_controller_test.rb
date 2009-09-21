require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
#require 'dns'
require 'rubygems'
require 'mocha'
require File.expand_path( File.join("test","plugin_basic_tests"), RailsParent.parent )

class DnsControllerTest < ActionController::TestCase

  def setup
    @model_class = DNS
    # FIXME: bad mock for DNS (field name mismatch):
    # DNS.stubs(:find).returns(DNS.new({"BAD" => ["d1", "d2"], "KEYS"=> ["s1", "s2"]}))

    # in test_access_show_xml:
    # add assert_response :success)
    # in case of error: give a nicer error than 500
    DNS.stubs(:find).returns(DNS.new({"searches" => ["d1", "d2"], "nameservers" => ["s1", "s2"]}))
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

