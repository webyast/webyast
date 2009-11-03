# 
# This "GET index" request will be called for each plugin.
# The loop over all available plugins is defined in checks.rake
#

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class PluginIndexTest < ActionController::TestCase
  fixtures :accounts
  def setup
    puts "Checking #{$pluginname}"
    @controller = Module.recursive_const_get( $pluginname ).new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
  end
  
  test "access index" do
    get :index
    assert_response :success
  end

end
