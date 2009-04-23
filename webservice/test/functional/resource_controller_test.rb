#
# test/functional/resource_controller_test.rb
#
# This tests proper returns for resource inspection
#
require 'test_helper'

class ResourceControllerTest < ActionController::TestCase

  require "lib/resource_registration"
  
  fixtures :domains, :resources
  
  def setup
    @prefix = "yast"
    # set up test routing
    ResourceRegistration.init
    ResourceRegistration.register_all ".", "resource_fixtures/good"
    ResourceRegistration.route_all
  end
  
  test "access root" do
    get :index
    assert_response :success
  end
  
  test "output xml format" do
    get :index, :format => "xml"
    assert_response :success
    assert @response.headers['Content-Type'] =~ %r{application/xml}
  end
  test "output html format" do
    get :index, :format => "html"
    assert_response :success
    assert @response.headers['Content-Type'] =~ %r{text/html}
  end
  
end
