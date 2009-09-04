require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'route'
require 'rubygems'
require 'mocha'
require File.expand_path( File.join("test","plugin_basic_tests"), RailsParent.parent )

class RoutesControllerTest < ActionController::TestCase

  def setup
    @model_class = Route
    Route.stubs(:find).returns(Route.new({"via" => "42.42.42.42"}))
    @controller = Network::RoutesController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
  end  

  # some cases fail because PluginBasicTests expects a singular controller
  #include PluginBasicTests

end

