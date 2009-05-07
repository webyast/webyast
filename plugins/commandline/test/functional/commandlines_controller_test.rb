require 'test_helper'

class CommandlinesControllerTest < ActionController::TestCase
  def setup
    @controller = Yast::CommandlinesController.new
  end
  
  # Replace this with your real tests.
  test "access index" do
    get :index
    assert_response :success
  end
end
