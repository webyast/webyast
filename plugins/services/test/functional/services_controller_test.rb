require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'rubygems'
require "scr"
require 'mocha'


class ServicesControllerTest < ActionController::TestCase
  fixtures :accounts
  def setup
    @controller = ServicesController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures

    s1 = Service.new
    s1.name = "foo"
    s1.status = 0

    s2 = Service.new
    s2.name = "cron"
    s2.status = 1
    
    Service.stubs(:find_all).returns([s1, s2])
    Service.stubs(:find).with("cron").returns([s2])
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
