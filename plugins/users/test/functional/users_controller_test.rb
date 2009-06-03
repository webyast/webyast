require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'rubygems'
require "scr"
require 'mocha'


class UsersControllerTest < ActionController::TestCase
  fixtures :accounts
  def setup
    @controller = UsersController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
    Scr.any_instance.stubs(:initialize)
    Scr.any_instance.stubs(:execute).with(['/sbin/yast2', 'users', 'list']).returns({:stderr=>"schubi19 \nschubi2 \nschubi5 \ntuxtux \n", :exit=>16, :stdout=>""})
    Scr.any_instance.stubs(:execute).with(['/sbin/yast2', 'users', 'show', 'username=schubi5']).returns({:stderr=>"Full Name:\n\tschubi5\nList of Groups:\n\t\nDefault Group:\n\tusers\nHome Directory:\n\t/home/schubi5\nLogin Shell:\n\t/bin/bash\nLogin Name:\n\tschubi5\nUID:\n\t1005\n", :exit=>16, :stdout=>""})
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
    get :show, :id => "schubi5"
    assert_response :success
  end

  test "access show with wrong user" do
    Scr.any_instance.stubs(:execute).with(['/sbin/yast2', 'users', 'show', 'username=schubi_not_found']).returns({:stderr=>"There is no such user.\n", :exit=>0, :stdout=>""})
    get :show, :id => "schubi_not_found"
    assert_response 404
  end

end
