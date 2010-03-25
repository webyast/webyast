#
# test/functional/sessions_controller_test.rb
#
#
require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class SessionsControllerTest < ActionController::TestCase
  fixtures :accounts

  def setup
    # Fake an active session
    # http://railsforum.com/viewtopic.php?id=1719
#    @request.session[:account_id] = 1 # defined in fixtures    
  end
  
  test "sessions new" do
    get :new
    assert_response 302 # redirect
  end
  
  test "sessions show" do
    get :show
    assert_response :success
  end
  
  test "sessions create" do
    get :create
    assert_response :success
  end
  
  test "sessions create with hash" do
    get :create, :hash => { "foo" => "bar" }
    assert_response :success
  end
  
  test "sessions create with login and password" do
    get :create, :hash => { :login => "test_user", :password => "test_password" }
    assert_response :success
  end
  
  test "sessions create fail with login and password" do
    get :create, :hash => { :login => "test_user", :password => "bad_password" }
    assert_response :success
  end
  
  test "sessions create fail with brute force protection" do
    BruteForceProtection.any_instance.stubs(:blocked?).returns(true)
    get :create, :hash => { :login => "test_user", :password => "bad_password" }
    assert_response :success
  end

  test "sessions create remember_me" do
    @request.session[:account_id] = 1 # defined in fixtures
    get :create, :remember_me => true
# FIXME   assert cookies[:auth_token]
    assert_response :success
  end
  
  test "sessions destroy" do
    get :destroy
    assert_response :success
  end
  
  test "output xml format" do
    get :show, :format => "xml"
    assert_response :success
    assert @response.headers['Content-Type'] =~ %r{application/xml}
  end
  
  test "output html format" do
    get :show, :format => "html"
    assert_response :success
    assert @response.headers['Content-Type'] =~ %r{text/html}
  end
  
end
