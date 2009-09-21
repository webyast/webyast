require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'


class AdministratorControllerTest < ActionController::TestCase
  fixtures :accounts

  def setup
    @controller = AdministratorController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures

    @model = Administrator.instance
    @model.stubs(:read_aliases).returns("")
  end
  
  test "check 'show' result" do

    ret = get :show
    # success (200 OK)
    assert_response :success

    # is returned a valid XML?
    ret_hash = Hash.from_xml(ret.body)
    assert ret_hash
    assert ret_hash.has_key?("administrator")
    assert ret_hash["administrator"].has_key?("aliases")
    Rails.logger.debug ret_hash.inspect
  end

end
