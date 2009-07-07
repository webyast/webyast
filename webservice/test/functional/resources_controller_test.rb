#
# test/functional/resources_controller_test.rb
#
# This tests proper returns for resource inspection
#
require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class TestPlugin
  attr_reader :directory
  def initialize path
    @directory = path
  end
end

class ResourcesControllerTest < ActionController::TestCase

  require "lib/resource_registration"
  
  def setup
    # set up test routing
    ResourceRegistration.reset
    plugin = TestPlugin.new "test/resource_fixtures/good"
    ResourceRegistration.register_plugin plugin
  end
  
  test "resources access root" do
    get :index
    assert_response :success
  end
  
  test "resources output xml format" do
    get :index, :format => "xml"
    assert_response :success
    assert @response.headers['Content-Type'] =~ %r{application/xml}
  end
  
  test "resources output html format" do
    get :index, :format => "html"
    assert_response :success
    assert @response.headers['Content-Type'] =~ %r{text/html}
  end
  
  test "resources by interfaces query" do
    ResourceRegistration.resources.each do |interface,implementations|
      get :index, :params => { "interface" => interface }
      assert_response :success
    end
  end  
  
end
