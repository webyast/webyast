require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'rubygems'
require "scr"
require 'mocha'

# Prevent contacting the system bus
# This looks ugly but the stubs(:initialize) below causes a warning
class Scr
  def initialize() end
end

class CommandsControllerTest < ActionController::TestCase
  fixtures :accounts
  def setup
    @controller = CommandsController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures

#    Scr.stubs(:initialize)
    # Scr, unused?
    Scr.any_instance.stubs(:execute).with(["/sbin/yast2",  "ntp-client",  "list"]).returns({:stderr=>"Server ntp1\nServer ntp2\nServer ntp3\n", :exit=>16, :stdout=>""})
    Scr.any_instance.stubs(:execute).with(["/sbin/yast2",  "ntp-client",  "status"]).returns({:stderr=>"NTP daemon is enabled.\n", :exit=>16, :stdout=>""})

    # Lsbservice.new
    opened = mock()
    opened.stubs(:eof?).returns(false, true)
    opened.stubs(:read).returns("Usage: mock-ntp {tick|tock}")
    IO.stubs(:popen).with("/etc/init.d/ntp", 'r+').yields(opened)
  end
  
  test "access index" do
    get :index , :service_id=>"ntp"
    assert_response :redirect
  end

#   test "access index xml" do
#     mime = Mime::XML
#     @request.accept = mime.to_s
#     get :index, :format => :xml, :service_id=>"ntp"
#     assert_equal mime.to_s, @response.content_type
#   end
  
#   test "access index json" do
#     mime = Mime::JSON
#     @request.accept = mime.to_s
#     get :index, :format => :json, :service_id=>"ntp"
#     assert_equal mime.to_s, @response.content_type
#   end

  test "execute service" do
    Scr.any_instance.stubs(:execute).with(['/etc/init.d/ntp', 'status']).returns({:exit=>0, :stdout=>"", :stderr=>""})

    put :update, :id=>"status", :service_id=>"ntp"
    assert_response :success
  end

  test "execute service with nil return of the SCR call" do
    Scr.any_instance.stubs(:execute).with(['/etc/init.d/ntp', 'status']).returns()

    put :update, :id=>"status", :service_id=>"ntp"
    assert_response 404
  end



end
