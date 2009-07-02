require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'rubygems'
require 'mocha'


class LanguageControllerTest < ActionController::TestCase
  fixtures :accounts
  def setup
    @controller = LanguageController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
  end



  def test_access_index
    #mock model to test only controller
    Language.any_instance.stubs(:read)
    get :show
    assert_response :success
  end

  def test_access_denied
    #mock model to test only controller
    Language.any_instance.stubs(:read)
    @controller.stubs(:permission_check).returns(false);
    get :show
    assert_response :forbidden
  end

  def test_access_show_xml
    Language.any_instance.stubs(:read)
    mime = Mime::XML
    @request.accept = mime.to_s
    get :show, :format => :xml
    assert_equal mime.to_s, @response.content_type
  end

  def test_access_show_json
    Language.any_instance.stubs(:read)
    mime = Mime::JSON
    @request.accept = mime.to_s
    get :show, :format => :json
    assert_equal mime.to_s, @response.content_type
  end

  Data = {:language => {
      :current => "cs_CZ",
      :utf8 => "true",
      :rootlocale => "false"
    }}

  def test_update   
    Language.any_instance.stubs(:save)
    put :update, Data
    check_update_result
  end

  def test_create
    Language.any_instance.stubs(:save)
    put :create, Data
    check_update_result
  end

  def check_update_result
    assert_response :success
    lang = assigns(:language)
    assert lang
    assert_equal lang.language, Data[:language][:current]
    assert_equal lang.utf8, Data[:language][:utf8]
    assert_equal lang.rootlocale, Data[:language][:rootlocale]
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
