require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'rubygems'
require 'systemtime'
require "scr"
require 'mocha'
require File.expand_path( File.join("test","plugin_basic_tests"), RailsParent.parent )

class SystemtimeControllerTest < ActionController::TestCase
  fixtures :accounts

    DATA = {:time => {
      :timezone => "Europe/Prague",
      :utcstatus => "true"
    }}

  def setup
    @model_class = Systemtime    
    
    Systemtime.stubs(:find).returns(Systemtime.new)

    @controller = SystemtimeController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
    @data = DATA
  end  

  include PluginBasicTests
  
  def test_update
    mock_save
    put :update, DATA
    assert_response :success
  end

  def test_create
    mock_save
    put :create, DATA
    assert_response :success
  end

  def mock_save
    YastService.stubs(:Call).with {
      |params,settings|
      params == "YaPI::TIME::Write" and
        settings["timezone"] == DATA[:time][:timezone] and
        settings["utcstatus"] == DATA[:time][:utcstatus] and
        ! settings.include?("currenttime")
    }
  end
end
