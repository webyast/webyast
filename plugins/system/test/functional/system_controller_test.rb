require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'


class SystemControllerTest < ActionController::TestCase
  fixtures :accounts

  def setup
    @controller = SystemController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures

    @model = System.instance
    @model.stubs(:hal_power_management).with(:reboot).returns(true)
    @model.stubs(:hal_power_management).with(:shutdown).returns(true)
  end
  
  test "check 'show' result" do
    ret = get :show
    # success (200 OK)
    assert_response :success

    # is returned a valid XML?
    ret_hash = Hash.from_xml(ret.body)
    assert ret_hash
    # actions active value must be a boolean
    assert ret_hash['actions']['reboot'].has_key? 'active' and
	(ret_hash['actions']['reboot']['active'] == true or ret_hash['actions']['reboot']['active'] == false)
    assert ret_hash['actions']['shutdown'].has_key? 'active' and
	(ret_hash['actions']['shutdown']['active'] == true or ret_hash['actions']['shutdown']['active'] == false)
  end

  test "don't change status on error" do
    ret = get :show
    # success (200 OK)
    assert_response :success

    orig = Hash.from_xml(ret.body)

    put :update, :system => {:shutdown => {:active => true}, :zzzzzz => {}}
    assert_response :missing

    ret = get :show
    # success (200 OK)
    assert_response :success

    assert orig == Hash.from_xml(ret.body)
  end


  test "request reboot" do
    ret = put :update, :system => {:reboot => {:active => true}}
    assert_response :success

    # :reboot action must be active
    assert Hash.from_xml(ret.body)['actions']['reboot']['active']
  end

  test "request shutdown" do
    ret = put :update, :system => {:shutdown => {:active => true}}
    assert_response :success

    # :shutdown action must be active
    assert Hash.from_xml(ret.body)['actions']['shutdown']['active']
  end


  # test access rights

  test "return error when not logged in" do
    # remember the current setting
    session_backup = @request.session
    @request.session = {} # the session is not defined

    ret = get :show
    # expect 401 Unauthorized error code
    assert_response :unauthorized

    # revert back the original session setting (for the following tests)
    @request.session = session_backup
  end

  test "return error when not permitted" do
    @controller.stubs(:permission_check).returns(false);

    ret = put :update, :system => {:reboot => {:active => true}}
    # expect 403 Forbidden error code
    assert_response :forbidden

    # set permissions back for the other tests
    @controller.stubs(:permission_check).returns(true);
  end


  # test invalid / malformed requests

  test "invalid (empty) request" do
    ret = put :update
    assert_response :missing
  end

  test "invalid (malformed) request" do
    ret = put :update, :zzzzzzz => :aaaaaaa
    assert_response :missing
  end

  test "invalid (empty actions) request" do
    ret = put :update, :system => {}
    assert_response :missing
  end

  test "invalid (unknown) request" do
    ret = put :update, :system => {:_invalid_action_ => {:active => true}}
    assert_response :missing
  end

  test "invalid (unexpected type) request" do
    ret = put :update, :system => {:reboot => :string}
    assert_response :missing
  end

  test "invalid (missing active parameter) request" do
    ret = put :update, :system => {:reboot => {}}
    assert_response :missing
  end

  test "invalid (non-boolean active parameter) request" do
    ret = put :update, :system => {:reboot => {:active => 'string'}}
    assert_response :missing
  end

end
