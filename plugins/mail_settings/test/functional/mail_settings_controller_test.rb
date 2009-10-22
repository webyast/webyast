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

  test "put failure" do
    YastService.stubs(:Call).with('YaPI::MailSettings::Write', {
      "Changed" => [ "i", 1],
      "MaximumMailSize" => [ "i", 10485760],
      "SendingMail" => ["a{sv}", {
	  "Type"	=> [ "s", "relayhost"],
	  "TLS"		=> [ "s", ""],
	  "RelayHost"	=> [ "a{sv}", {
	      "Name"	=> [ "s", "smtp.newdomain.com"],
	      "Auth"	=> [ "i", 0],
	      "Account"	=> [ "s", ""],
	      "Password"=> [ "s", ""]
	  }]
      }]
   
    }).returns("Unknown mail sending TLS type. Allowed values are: NONE | MAY | MUST | MUST_NOPEERMATCH")

    ret = put :update, :mail_settings => {:smtp_server => "smtp.newdomain.com"}

    ret_hash = Hash.from_xml(ret.body)

    assert_response 503
    assert ret_hash
    assert ret_hash.has_key?("error")
    assert ret_hash["error"]["type"] == "MAIL_SETTINGS_ERROR"
  end


end
