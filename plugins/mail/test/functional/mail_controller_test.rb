require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'


class MailControllerTest < ActionController::TestCase
  fixtures :accounts

  def setup
    @controller = MailController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures

    @model = Mail.instance
    @model.stubs(:read).returns(true)
  end
  
  test "check 'show' result" do

    ret = get :show
    # success (200 OK)
    assert_response :success

    # is returned a valid XML?
    ret_hash = Hash.from_xml(ret.body)
    assert ret_hash
    assert ret_hash.has_key?("mail")
    assert ret_hash["mail"].has_key?("smtp_server")
  end

  test "put success" do
    @model.stubs(:save).with({'smtp_server' => "newserver"}).returns(true)

    ret = put :update, :mail => {:smtp_server => "newserver"}
    ret_hash = Hash.from_xml(ret.body)

    assert_response :success
    assert ret_hash
    assert ret_hash.has_key?("mail")
  end

# shame, YaPI currently always succeedes
#  test "put failure" do
#  end


end
