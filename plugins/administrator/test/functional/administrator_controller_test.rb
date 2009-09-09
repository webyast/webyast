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
  end
  
  test "check 'show' result" do
    ret = get :show
    # success (200 OK)
    assert_response :success

    # is returned a valid XML?
    ret_hash = Hash.from_xml(ret.body)
    assert ret_hash
    assert ret_hash.has_key?("aliases")
    assert ret_hash["aliases"].is_a? Array
  end

end
