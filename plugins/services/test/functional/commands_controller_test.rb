require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'rubygems'
require "scr"
require 'mocha'


class CommandsControllerTest < ActionController::TestCase
  fixtures :accounts
  def setup
    @controller = CommandsController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
    Scr.any_instance.stubs(:initialize)
    Scr.any_instance.stubs(:execute).with(["/sbin/yast2",  "ntp-client",  "list"]).returns({:stderr=>"Server ntp1\nServer ntp2\nServer ntp3\n", :exit=>16, :stdout=>""})
    Scr.any_instance.stubs(:execute).with(["/sbin/yast2",  "ntp-client",  "status"]).returns({:stderr=>"NTP daemon is enabled.\n", :exit=>16, :stdout=>""})


  end
  
  test "access index" do
    get :index , :service_id=>"ntp"
    assert_response :success
  end

  test "access index xml" do
    mime = Mime::XML
    @request.accept = mime.to_s
    get :index, :format => :xml, :service_id=>"ntp"
    assert_equal mime.to_s, @response.content_type
  end
  
  test "access index json" do
    mime = Mime::JSON
    @request.accept = mime.to_s
    get :index, :format => :json, :service_id=>"ntp"
    assert_equal mime.to_s, @response.content_type
  end

  test "execute service" do
    Scr.any_instance.stubs(:execute).with(['/usr/sbin/rcntp', 'status']).returns({:exit=>0, :stdout=>"", :stderr=>""})

    put :update, :id=>"status", :service_id=>"ntp"
    assert_response :success
  end

  test "execute service with nil return of the SCR call" do
    Scr.any_instance.stubs(:execute).with(['/usr/sbin/rcntp', 'status']).returns()

    put :update, :id=>"status", :service_id=>"ntp"
    assert_response 404
  end



end
