#
# Testing PermissionsController
#

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
    
    # Fake an active session
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
    
    Scr.any_instance.stubs(:execute).with(["polkit-action"]).returns({:stderr=>"", :exit=>0, :stdout=>"org.opensuse.yast.system.users.read\norg.opensuse.yast.system.users.write\norg.opensuse.yast.system.users.new\norg.opensuse.yast.system.users.delete\n"})
    Scr.any_instance.stubs(:execute).with(["polkit-auth", "--user", "test_user", "--explicit"]).returns(:stderr=>"", :exit=>0, :stdout=>"org.opensuse.yast.system.users.read\norg.opensuse.yast.system.users.write\norg.opensuse.yast.system.users.new\norg.opensuse.yast.permissions.write\n")
    Scr.any_instance.stubs(:execute).with(['polkit-auth', '--user', 'test_user', '--grant', 'org.opensuse.yast.patch.install']).returns({:stderr=>"", :exit=>0, :stdout=>""})
  end
  
  test "permissions access index" do
    get :index, :user_id => "test_user"
    assert_response :success
  end

  test "permissions access index production" do
    save = ENV['RAILS_ENV']
    ENV['RAILS_ENV'] = "production"
    get :index
    ENV['RAILS_ENV'] = save
    assert_response 503
  end

  test "permissions access index xml" do
    mime = Mime::XML
    @request.accept = mime.to_s
    get :index, :user_id => "test_user", :format => :xml
    assert_equal mime.to_s, @response.content_type
  end
  
  test "permissions access index json" do
    mime = Mime::JSON
    @request.accept = mime.to_s
    get :index, :user_id => "test_user", :format => :json
    assert_equal mime.to_s, @response.content_type
  end

  test "permissions access index without user" do
    get :index
    assert_response 404
  end

  test "permissions access index with wrong user" do
    Scr.any_instance.stubs(:execute).with(["polkit-auth", "--user", "not avail", "--explicit"]).returns({:stderr=>"polkit-auth: cannot look up uid for user 'not avail'\n", :exit=>1, :stdout=>""})
    get :index, :user_id => "not avail"
    assert_response 404
  end

  test "permissions access show" do
    get :show, :id => "org.opensuse.yast.system.users.read", :user_id => "test_user"
    assert_response :success
  end

  test "permissions access show blank id" do
    get :show, :user_id => "test_user"
    assert_response 404
  end

  test "permissions access show json" do
    mime = Mime::JSON
    @request.accept = mime.to_s
    get :show, :id => "org.opensuse.yast.system.users.read", :user_id => "test_user"
    assert_response :success
  end

  test "permissions access no session" do
    save = ENV['RAILS_ENV']
    ENV['RAILS_ENV'] = "production" # do a real permission_check
    uid = @request.session[:account_id]
    @request.session[:account_id] = 0
    get :show
    @request.session[:account_id] = uid
    ENV['RAILS_ENV'] = save
    assert_response 401
  end
  
  test "permissions access show production" do
    save = ENV['RAILS_ENV']
    ENV['RAILS_ENV'] = "production" # do a real permission_check
    get :show, :id => "org.opensuse.yast.system.read"
    ENV['RAILS_ENV'] = save
    assert_response 503
  end

  test "permissions access show without right" do
    save = ENV['RAILS_ENV']
    ENV['RAILS_ENV'] = "production"
    get :show, :user_id => "nobody"
    ENV['RAILS_ENV'] = save
    assert_response 404
  end

  test "permissions access show without user" do
    get :show, :id => "org.opensuse.yast.system.users.read"
    assert_response 404
  end

  test "permissions access show without user AND right" do
    get :show
    assert_response 404
  end

  test "permissions setting" do
    put :update, :permissions => {"name"=>"org.opensuse.yast.patch.install", "id"=>"test_user", "grant"=>true}, :id=>"test_user"
    assert_response :success
  end

  test "permissions setting blank" do
    put :update, :id=>"test_user"
    assert_response 404
  end

  test " setting permissions without permissions" do
    save = ENV['RAILS_ENV']
    ENV['RAILS_ENV'] = "production"
    put :update, :id=>"nobody"
    ENV['RAILS_ENV'] = save
    assert_response 503
  end

  test "setting permissions without user" do
    put :update, :permissions => {"name"=>"org.opensuse.yast.patch.install", "grant"=>true}
    assert_response 404
  end

  test "setting permissions returns false from polkit-auth" do
    Scr.any_instance.stubs(:execute).with(['polkit-auth', '--user', 'test_user', '--grant', 'org.opensuse.yast.patch.install']).returns({:stderr=>"error", :exit=>1, :stdout=>""})
    put :update, :permissions => {"name"=>"org.opensuse.yast.patch.install", "id"=>"test_user", "grant"=>true}, :id=>"test_user"
    assert_response 404
  end

end
