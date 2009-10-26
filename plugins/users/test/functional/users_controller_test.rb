require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require "scr"
require "yast_service"
require 'mocha'


class UsersControllerTest < ActionController::TestCase
  fixtures :accounts
  def setup
    @controller = UsersController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures

    User.stubs(:find_all).returns([])    
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
    u = User.new
    u.load_attributes({:uid => "schubi5"})
    User.stubs(:find).with("schubi5").returns(u)
    get :show, :id => "schubi5"
    assert_response :success
  end

  test "access show with wrong user" do
    User.stubs(:find).with("schubi_not_found").returns(nil)
    get :show, :id => "schubi_not_found"
    assert_response 404
  end

end
