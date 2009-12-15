require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'mocha'
require File.expand_path( File.join("test","plugin_basic_tests"), RailsParent.parent )

class SystemtimeControllerTest < ActionController::TestCase
  fixtures :accounts

    INITIAL_DATA = {
      :timezone => "Europe/Prague",
      :time => "12:18:00",
      :date => "02/07/2009",
      :utcstatus => "true" }
    TEST_TIMEZONES = [{
      "name" => "Europe",
      "central" => "Europe/Prague",
      "entries" => {
        "Europe/Prague" => "Czech Republic",
        "Europe/Kiev" => "Ukraine (Kiev)"
      }
    },
    {
      "name" => "USA",
      "central" => "America/Chicago",
      "entries" => {
        "America/Chicago" => "Central (Chicago)",
        "America/Kentucky/Monticello" => "Kentucky (Monticello)"
      }
    }
    ]
    DATA = {:systemtime => {
      :timezone => "Europe/Prague",
      :utcstatus => "true"
    }}

  def setup
    @model_class = Systemtime
    
    time_mock = Systemtime.new(INITIAL_DATA)
    time_mock.timezones = TEST_TIMEZONES
    Systemtime.stubs(:find).returns(time_mock)

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
      ret = params == "YaPI::TIME::Write" &&
        settings["timezone"] == DATA[:systemtime][:timezone] &&
        settings["utcstatus"] == DATA[:systemtime][:utcstatus] &&
        ! settings.include?("currenttime")
      ret2 = params == "YaPI::SERVICES::Execute"
      return ret || ret2
    }
    Systemtime.stubs(:permission_check)
  end
end
