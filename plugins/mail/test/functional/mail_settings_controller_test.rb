require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'


class MailSettingsControllerTest < ActionController::TestCase
  fixtures :accounts

  def setup
    @controller = MailSettingsController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures

    @model = MailSettings.instance
    @model.stubs(:read).returns(true)
  end
  
  test "check 'show' result" do

    ret = get :show
    # success (200 OK)
    assert_response :success

    # is returned a valid XML?
    ret_hash = Hash.from_xml(ret.body)
    assert ret_hash
    assert ret_hash.has_key?("mail_settings")
    assert ret_hash["mail_settings"].has_key?("smtp_server")
  end

  test "put success" do
    @model.stubs(:save).with({'smtp_server' => "newserver"}).returns(true)

    ret = put :update, :mail_settings => {:smtp_server => "newserver"}
    ret_hash = Hash.from_xml(ret.body)

    assert_response :success
    assert ret_hash
    assert ret_hash.has_key?("mail_settings")
  end

# shame, YaPI currently always succeedes
#  test "put failure" do
#  end


end
