require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'rubygems'
require "scr"
require 'mocha'
require File.expand_path( File.join("test","plugin_basic_tests"), RailsParent.parent )

class SystemtimesControllerTest < ActionController::TestCase
  fixtures :accounts

    DATA = {:time => {
      :timezone => "Europe/Prague",
      :utcstatus => "true"
    }}

  def setup
    @model_class = Systemtime

    Systemtime.stubs(:find).returns([Systemtime.new, Systemtime.new])
    
    @controller = SystemtimesController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
    @data = DATA
  end  

  include PluginBasicTests
  
  def test_update
    Systemtime.any_instance.stubs(:save)
    put :update, DATA
    check_update_result
  end

  def test_create
    Systemtime.any_instance.stubs(:save)
    put :create, DATA
    check_update_result
  end

  def check_update_result
    assert_response :success
    time = assigns(:systemtime)
    assert time
    assert_equal DATA[:time][:timezone], time.timezone
    assert_equal DATA[:time][:utcstatus], time.utcstatus
    assert_nil time.date
    assert_nil time.time
  end
end
