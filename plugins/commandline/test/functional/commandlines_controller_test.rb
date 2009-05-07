require 'test_helper'

class CommandlinesControllerTest < ActionController::TestCase
  fixtures :accounts
  def setup
    @controller = Yast::CommandlinesController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures
  end
  
  test "access index" do
    get :index
    assert_response :success
  end

  test "access index xml" do
    mime = Mime::XML
    @request.accept = mime.to_s
    get :index
    assert_equal @response.content_type, mime
  end
  
  test "access index json" do
    mime = Mime::JSON
    @request.accept = mime.to_s
    get :index
    assert_equal @response.content_type, mime
    puts @response.body
  end
  
  test "return html request with xml" do
    get :index, :format => "html"
    assert_equal @response.content_type, Mime::XML.to_s
  end
  
end
