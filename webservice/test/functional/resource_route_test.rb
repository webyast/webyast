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
  
  # ResourceRegistration.init drops all database content
  
  test "resource initialization" do
    ResourceRegistration.init
    ResourceRegistration.register_all ".", "resource_fixtures/good"
    ResourceRegistration.route_all
    assert_generates "/yast", :controller => "yast", :action => "index"
  end
  
end
