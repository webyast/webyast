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

    s1 = Lsbservice.new("foo")
    s1.stubs(:path).returns("/foo")
    s1.stubs(:commands).returns(["start", "stop"])

    s2 = Lsbservice.new("cron")
    s2.stubs(:path).returns("/cron")
    s2.stubs(:commands).returns(["start", "stop", "kill"])

    Lsbservice.stubs(:all).returns([s1, s2])
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
