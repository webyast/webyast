require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class SecurityControllerTest < ActionController::TestCase
  fixtures :accounts
  def setup
    @controller = SecuritiesController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
  end

  def test_show # must run as root, uses scr.execute
    @request.session[:account_id] = 1 # defined in fixtures
    get :show
    assert_response :success
  end

  def test_update # must run as root, uses scr.execute
    @request.session[:account_id] = 1 # defined in fixtures
    get :update, :security => {:firewall => true, :firewall_after_startup => true, :ssh => true}
  end

  def test_actions_not_logged_in
    actions = %w{show create update} #index?
    actions.each do |ac|
      get ac
      assert_response :unauthorized
      assert_equal nil, flash[:notice]
   end
  end

=begin
  def test_xml_response
    test "access show xml" do
      mime = Mime::XML
      @request.accept = mime.to_s
      get :show, :format => :xml
      assert_equal mime.to_s, @response.content_type
    end
  end

  def test_json_response
    test "access show json" do
      mime = Mime::JSON
      @request.accept = mime.to_s
      get :show, :format => :json
      assert_equal mime.to_s, @response.content_type
    end
  end
=end
end

