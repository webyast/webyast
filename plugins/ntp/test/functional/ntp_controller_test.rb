require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'test/unit'

#don't have plugin basic tests because doesn't have read permission


class SystemControllerTest < ActionController::TestCase
  fixtures :accounts

  def setup    
    @controller = NtpController.new
    @request = ActionController::TestRequest.new
    # http://railsforum.com/viewtopic.php?id=1719
    @request.session[:account_id] = 1 # defined in fixtures    
    YastService.stubs(:Call).with("YaPI::NTP::Available").returns(true)
  end


  def test_index
    ret = get :show
    assert_response :success
    response = Hash.from_xml(ret.body)
    assert response["actions"]["synchronize"] == false
  end

  def test_update
    YastService.stubs(:Call).with("YaPI::NTP::Synchronize",true).once.returns("OK")
    post :update, {"ntp"=>{"synchronize"=>true,"synchronize_utc"=>true}}
    assert_response :success
  end

  def test_update_failed
    YastService.stubs(:Call).with("YaPI::NTP::Synchronize",false).once.returns("Failed")
    post :update, {"ntp"=>{"synchronize"=>true,"synchronize_utc" => false}}
    assert_response 503
  end

end
