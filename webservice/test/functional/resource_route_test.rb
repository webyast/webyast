#
# test/functional/resource_route_test.rb
#
# This tests route creation from the resource database
#
require 'test_helper'

class ResourceRouteTest < ActiveSupport::TestCase

  # See http://pennysmalls.com/2009/03/04/rails-23-breakage-and-fixage/
  include ActionController::Assertions::RoutingAssertions
  
  require "lib/resource"
  
  fixtures :domains, :resources
  
  # test routing
  # /yast -> links to all domains
  # /yast/<domain> -> links to all resources within this domain
  # /yast/<domain>/<resource> -> RESTful resource
  
  test "resource initialization" do
    ResourceRegistration.init
    ResourceRegistration.register_all ".", "resource_fixtures/good"
    ResourceRegistration.route_all
    assert_generates "/", :controller => "resource", :action => "index"
  end
  
end
