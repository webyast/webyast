require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'
require 'rubygems'
require "scr"
require 'mocha'
require File.expand_path( File.join("test","plugin_basic_tests"), RailsParent.parent )

class StatusControllerTest < ActionController::TestCase
  fixtures :accounts

  def setup
    @model_class = Status

    Status.any_instance.stubs(:check_collectd).returns(true)
    Status.stubs(:find).returns([Status.new, Status.new])
    
    @controller = StatusController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
  end  

  include PluginBasicTests

  def test_update_noparams
    # nothing
  end

  def test_update_noperm
    # nothing
  end

  # FIXME 
  def test_access_show_json
    # ActionView::MissingTemplate: Missing template status/show.erb in view path app/views:.
  end
end

