require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'rubygems'
require "scr"
require 'mocha'


class PermissionsControllerTest < ActionController::TestCase
  fixtures :accounts
  def setup
    @controller = PermissionsController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
    Scr.any_instance.stubs(:execute).with(["polkit-action"]).returns({:stderr=>"", :exit=>0, :stdout=>"org.opensuse.yast.system.users.read\norg.opensuse.yast.system.users.write\norg.opensuse.yast.system.users.new\norg.opensuse.yast.system.users.delete\n"})
    Scr.any_instance.stubs(:execute).with(["polkit-auth", "--user", "schubi", "--explicit"]).returns(:stderr=>"", :exit=>0, :stdout=>"org.opensuse.yast.system.users.read\norg.opensuse.yast.system.users.write\norg.opensuse.yast.system.users.new\n")
    Scr.any_instance.stubs(:execute).with(['polkit-auth', '--user', 'schubi', '--grant', 'org.opensuse.yast.patch.install']).returns({:stderr=>"", :exit=>0, :stdout=>""})
  end
  
  test "access index" do
    get :index, :user_id => "schubi"
    assert_response :success
  end

  test "access index xml" do
    mime = Mime::XML
    @request.accept = mime.to_s
    get :index, :user_id => "schubi", :format => :xml
    assert_equal mime.to_s, @response.content_type
  end
  
  test "access index json" do
    mime = Mime::JSON
    @request.accept = mime.to_s
    get :index, :user_id => "schubi", :format => :json
    assert_equal mime.to_s, @response.content_type
  end

  test "access index without user" do
    get :index
    assert_response 404
  end

  test "access index with wrong user" do
    Scr.any_instance.stubs(:execute).with(["polkit-auth", "--user", "not avail", "--explicit"]).returns({:stderr=>"polkit-auth: cannot look up uid for user 'not avail'\n", :exit=>1, :stdout=>""})
    get :index, :user_id => "not avail"
    assert_response 404
  end

  test "access show" do
    get :show, :id => "org.opensuse.yast.system.users.read", :user_id => "schubi"
    assert_response :success
  end

  test "access show without right" do
    get :show, :user_id => "schubi"
    assert_response 404
  end

  test "access show without user" do
    get :show, :id => "org.opensuse.yast.system.users.read"
    assert_response 404
  end

  test "access show without user AND right" do
    get :show
    assert_response 404
  end

  test "setting permissions" do
    put :update, :permissions => {"name"=>"org.opensuse.yast.patch.install", "id"=>"schubi", "grant"=>true}, :id=>"schubi.xml"
    assert_response :success
  end

  test "setting permissions without permissions" do
    put :update, :id=>"schubi.xml"
    assert_response 404
  end

  test "setting permissions without user" do
    put :update, :permissions => {"name"=>"org.opensuse.yast.patch.install", "id"=>"schubi", "grant"=>true}
    assert_response 404
  end

  test "setting permissions returns false from polkit-auth" do
    Scr.any_instance.stubs(:execute).with(['polkit-auth', '--user', 'schubi', '--grant', 'org.opensuse.yast.patch.install']).returns({:stderr=>"error", :exit=>1, :stdout=>""})
    put :update, :permissions => {"name"=>"org.opensuse.yast.patch.install", "id"=>"schubi", "grant"=>true}, :id=>"schubi.xml"
    assert_response 404
  end

end
