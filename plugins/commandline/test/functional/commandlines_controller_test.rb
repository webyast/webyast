require 'test_helper'

class CommandlinesControllerTest < ActionController::TestCase
  fixtures :accounts
  def setup
    @controller = Yast::CommandlinesController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
  end
  
  # Replace this with your real tests.
  test "access index" do
    get :index
    assert_response :success
  end
end
