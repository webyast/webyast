require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'rubygems'
require "scr"
require 'mocha'


class SystemtimesControllerTest < ActionController::TestCase
  fixtures :accounts
  def setup
    @controller = SystemtimesController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
  end

  test "access show" do
    Systemtime.any_instance.stubs(:read)
    get :show
    assert_response :success
  end

  def test_access_denied
    #mock model to test only controller
    Systemtime.any_instance.stubs(:read)
    @controller.stubs(:permission_check).returns(false);
    get :show
    assert_response :forbidden
  end


  def test_access_show_xml
    Systemtime.any_instance.stubs(:read)
    mime = Mime::XML
    @request.accept = mime.to_s
    get :show, :format => :xml
    assert_equal mime.to_s, @response.content_type
  end

  def test_access_show_json
    Systemtime.any_instance.stubs(:read)
    mime = Mime::JSON
    @request.accept = mime.to_s
    get :show, :format => :json
    assert_equal mime.to_s, @response.content_type
  end

  Data = {:time => {
      :timezone => "Europe/Prague",
      :utcstatus => "true"
    }}

  def test_update
    Systemtime.any_instance.stubs(:save)
    put :update, Data
    check_update_result
  end

  def test_create
    Systemtime.any_instance.stubs(:save)
    put :create, Data
    check_update_result
  end

  def check_update_result
    assert_response :success
    time = assigns(:systemtime)
    assert time
    assert_equal Data[:time][:timezone], time.timezone
    assert_equal Data[:time][:utcstatus], time.utcstatus
    assert_nil time.datetime
  end

  def test_update_noparams
    Language.any_instance.stubs(:save)
    put :update
    assert_response :missing
  end

  def test_update_noperm
    #ensure that nothink is saved
    Language.any_instance.expects(:save).never

    @controller.stubs(:permission_check).returns(false);

    put :update, Data

    assert_response  :forbidden
  end
end