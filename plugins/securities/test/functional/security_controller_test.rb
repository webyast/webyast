require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class SecurityControllerTest < ActionController::TestCase
  fixtures :accounts
  def setup
    @controller = SecuritiesController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
  end

  def test_actions_not_logged_in
#    actions = %w{:show :create :update} #index?
#    actions.each do |ac|
    get :show
    assert_response :unauthorized
    assert_equal nil, flash[:notice]
    get :update
    assert_response :unauthorized
    assert_equal nil, flash[:notice]
    get :create
    assert_response :unauthorized
    assert_equal nil, flash[:notice]
#   end
  end

  def test_show # must run as root, uses scr.execute
    @request.session[:account_id] = 1 # defined in fixtures
    get :show
    assert_response :success
  end

  def test_update_with_params # must run as root, uses scr.execute
    @request.session[:account_id] = 1
    get :update, :security => {:firewall => true, :firewall_after_startup => true, :ssh => true}
    assert_response :success
  end

  def test_update_without_params
    @request.session[:account_id] = 1
    get :update
    assert_response 404, "update without params should not succeed"
  end

  def test_show_xml
    @request.session[:account_id] = 1
    mime = Mime::XML
    @request.accept = mime.to_s
    get :show, :format => :xml
    assert_equal mime.to_s, @response.content_type
  end

  def test_show_json
    @request.session[:account_id] = 1
    mime = Mime::JSON
    @request.accept = mime.to_s
    get :show, :format => :json
    assert_equal mime.to_s, @response.content_type
  end
end

