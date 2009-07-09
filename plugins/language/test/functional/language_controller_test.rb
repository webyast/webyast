require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'rubygems'
require 'mocha'
require File.expand_path( File.join("lib","plugin_basic_tests"), RailsParent.parent )

class LanguageControllerTest < ActionController::TestCase
  fixtures :accounts
  
  def setup
    @model_class = Language
    @controller = LanguageController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
    @data = Data
  end

  include PluginBasicTests

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
end
