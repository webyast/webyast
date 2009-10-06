require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'route'
require 'rubygems'
require 'mocha'
require File.expand_path( File.join("test","plugin_basic_tests"), RailsParent.parent )

class RoutesControllerTest < ActionController::TestCase

  def setup
    @model_class = Route
    d = Route.new({"id" => "default", "via" => "42.42.42.42"})
    Route.stubs(:find).with("default").returns(d)
    Route.stubs(:find).with(:all).returns({"default" => d})
    @controller = Network::RoutesController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
  end  

  # some cases fail because PluginBasicTests expects a singular controller
  #include PluginBasicTests

  def test_show_xml
    get :show, :format => 'xml', :id => 'default'
    h = Hash.from_xml @response.body
    assert_instance_of String, h['route']['via']
  end

  def test_index_xml
    get :index, :format => 'xml'
    h = Hash.from_xml @response.body
    assert_instance_of Array, h["routes"]
    assert_equal "default",   h["routes"][0]["id"]
  end

  DATA={"routes"=>{
       "id"=>"default",
       "via"=>"10.20.30"
	 },
      "id"=>"default"
     }
  ERROR = {
    "exit" => "-1",
    "error" => "invalid ip",
  }

  def test_validation
    @model_class.any_instance.stubs(:save).returns ERROR
    put :update, DATA
    h = Hash.from_xml @response.body
    assert_equal "NETWORK_ROUTE_ERROR", h["error"]["type"]
    assert_response :error
  end

end

