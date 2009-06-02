require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'rubygems'
require "scr"
require 'mocha'


class ConfigNtpControllerTest < ActionController::TestCase
  fixtures :accounts
  def setup
    @controller = ConfigNtpController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
    Scr.any_instance.stubs(:initialize)
    Scr.any_instance.stubs(:execute).with(["/sbin/yast2",  "ntp-client",  "list"]).returns({:stderr=>"Server ntp1\nServer ntp2\nServer ntp3\n", :exit=>16, :stdout=>""})
    Scr.any_instance.stubs(:execute).with(["/sbin/yast2",  "ntp-client",  "status"]).returns({:stderr=>"NTP daemon is enabled.\n", :exit=>16, :stdout=>""})


  end
  
  test "access show" do
    get :show
    assert_response :success
  end

  test "access show xml" do
    mime = Mime::XML
    @request.accept = mime.to_s
    get :show, :format => :xml
    assert_equal mime.to_s, @response.content_type
  end
  
  test "access show json" do
    mime = Mime::JSON
    @request.accept = mime.to_s
    get :show, :format => :json
    assert_equal mime.to_s, @response.content_type
  end

  test "access show with a SCR call which returns nil" do
    Scr.any_instance.stubs(:execute).with(["/sbin/yast2",  "ntp-client",  "list"]).returns()
    Scr.any_instance.stubs(:execute).with(["/sbin/yast2",  "ntp-client",  "status"]).returns()
    get :show
    assert_response :success
  end


end
