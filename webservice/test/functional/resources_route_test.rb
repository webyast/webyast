#
# test/functional/resource_route_test.rb
#
# This tests route creation from the resource database
#
class TestPlugin
  attr_reader :directory
  def initialize path
    @directory = File.join(File.dirname(__FILE__), "..", path)
  end
end

RESOURCE_REGISTRATION_TESTING = true # prevent plugin registration in environment.rb
require File.join(File.dirname(__FILE__), "..", "test_helper")
require File.join(File.dirname(__FILE__), "..", "..", "lib", "resource_registration")

class ResourceRouteTest < ActiveSupport::TestCase

  # See http://pennysmalls.com/2009/03/04/rails-23-breakage-and-fixage/
  include ActionController::Assertions::RoutingAssertions
  
  # config/initializers/resource_registration.rb sets it up
  
  test "resource route initialization" do
    
    plugin = TestPlugin.new "resource_fixtures/good"
    ResourceRegistration.reset
    ResourceRegistration.register_plugin plugin
    ResourceRegistration.route ResourceRegistration.resources

#    $stderr.puts ActionController::Routing::Routes.routes
    
    # root URI links to ResourcesController.index
    assert_recognizes( { :controller => "resources", :action => "index" }, "/" )
    # as does /resources
    assert_routing( { :path => "/resources", :method => :get }, { :controller => "resources", :action => "index" } )
    
    # Ensure there is a route for every resource
    ResourceRegistration.resources.each do |interface,implementations|
      implementations.each do |implementation|
	if implementation[:singular]
	  assert_generates "#{implementation[:controller]}", { :controller => "#{implementation[:controller]}", :action => :show }
	else
	  assert_generates "#{implementation[:controller]}", { :controller => "#{implementation[:controller]}", :action => :index }
	end
      end
    end
  end
  
end
