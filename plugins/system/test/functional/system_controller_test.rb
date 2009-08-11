require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'


class SystemControllerTest < ActionController::TestCase
  fixtures :accounts

  def setup
    @controller = SystemController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
  end
  
  test "check 'show' result" do
    get :show
    assert_response :success
  end

end
