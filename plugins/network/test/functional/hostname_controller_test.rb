require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'hostname'
require 'mocha'
require File.expand_path( File.join("test","plugin_basic_tests"), RailsParent.parent )

class HostnameControllerTest < ActionController::TestCase

  def setup
    @model_class = Hostname
    Hostname.stubs(:find).returns(Hostname.new({"name" => "BAD", "domain" => "DOMAIN"}))
    @controller = Network::HostnameController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
  end  

  def test_content_of_xml
    get :show, :format => 'xml'
    h=Hash.from_xml @response.body
    assert_equal 'BAD', h['hostname']['name']
    assert_equal 'DOMAIN', h['hostname']['domain']
  end

  include PluginBasicTests

end

