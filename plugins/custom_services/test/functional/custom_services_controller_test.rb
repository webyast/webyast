require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'rubygems'
require 'mocha'


class CustomServicesControllerTest < ActionController::TestCase
  fixtures :accounts
  def setup
    @controller = CustomServicesController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures

    s1 = CustomService.new
    s1.name = "foo"
    s1.status = 0

    s2 = CustomService.new
    s2.name = "cron"
    s2.status = 1
    
    CustomService.stubs(:find_all).returns([s1, s2])
    CustomService.stubs(:find).with("cron").returns([s2])
  end
  
  test "access index" do
    get :index
    assert_response :success
  end

  test "access index xml" do
    mime = Mime::XML
    @request.accept = mime.to_s
    get :index, :format => :xml
    assert_equal mime.to_s, @response.content_type
  end
  
  test "access index json" do
    mime = Mime::JSON
    @request.accept = mime.to_s
    get :index, :format => :json
    assert_equal mime.to_s, @response.content_type
  end

  test "access show" do
    get :show, :id =>"cron"
    assert_response :success
  end

end
