#
# test/functional/resources_controller_test.rb
#
# This tests proper returns for resource inspection
#

class TestPlugin
  attr_reader :directory
  def initialize path
    @directory = File.join(File.dirname(__FILE__), "..", path)
  end
end

unless defined? RESOURCE_REGISTRATION_TESTING
  RESOURCE_REGISTRATION_TESTING = true # prevent plugin registration in environment.rb
end
require File.join(File.dirname(__FILE__), "..", "test_helper")
require File.join(File.dirname(__FILE__), "..", "..", "lib", "resource_registration")

class ResourcesControllerTest < ActionController::TestCase

  def setup
    # set up test routing
    ResourceRegistration.reset
    plugin = TestPlugin.new "resource_fixtures/good"
    ResourceRegistration.register_plugin plugin
    ResourceRegistration.route ResourceRegistration.resources
  end
  
  test "resources access root" do
    get :index
    assert_response :success
  end
  
  test "resources index with interface" do
    get :index, :id => "org.opensuse.test"
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
      get :index, :params => { "id" => interface }
      assert_response :success
    end
  end  
  
end
