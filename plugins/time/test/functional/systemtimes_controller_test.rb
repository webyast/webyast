require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'rubygems'
require "scr"
require 'mocha'
require File.expand_path( File.join("lib","plugin_basic_tests"), RailsParent.parent )

class SystemtimesControllerTest < ActionController::TestCase
  fixtures :accounts

    Data = {:time => {
      :timezone => "Europe/Prague",
      :utcstatus => "true"
    }}

  def setup
    @model_class = Systemtime
    @controller = SystemtimesController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
    @data = Data
  end  

  include PluginBasicTests
  
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
end