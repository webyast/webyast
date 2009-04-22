#
# test/functional/resource_route_test.rb
#
# This tests route creation from the resource database
#
require 'test_helper'

class ResourceRouteTest < ActiveSupport::TestCase

  # See http://pennysmalls.com/2009/03/04/rails-23-breakage-and-fixage/
  include ActionController::Assertions::RoutingAssertions
  
  require "lib/resource_registration"
  
  fixtures :domains, :resources
  
  # ResourceRegistration.init drops all database content
  
  test "resource route initialization" do
    ResourceRegistration.init
    ResourceRegistration.register_all ".", "resource_fixtures/good"
    ResourceRegistration.route_all
    
#    $stderr.puts ActionController::Routing::Routes.routes
    
    prefix = "yast"
    
    # root URI links to ResourceController.index
    assert_generates "/#{prefix}", :controller => "resource", :action => "index"
    assert_routing( { :path => "/#{prefix}", :method => :get }, { :controller => "resource", :action => "index" } )
    
    # Ensure there is a route for every resource
    Resource.find(:all).each do |resource|
#      assert_routing "/#{prefix}/#{resource.domain}/#{resource}", { :path => "#{resource.domain}/#{resource}", :method => :get }
    end
  end
  
end
