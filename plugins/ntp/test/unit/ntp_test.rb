require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

require 'system'

class NtpTest < ActiveSupport::TestCase

  def setup    
    YastService.stubs(:Call).with("YaPI::NTP::Available").once.returns(true)
    @model = Ntp.find
  end

  def test_actions
    assert_not_nil @model.actions
    assert_instance_of(Hash, @model.actions, "action() returns Hash")
  end

  def test_synchronize_ok
    @model.actions[:synchronize] = true
    @model.actions[:synchronize_utc] = true
    YastService.stubs(:Call).with("YaPI::NTP::Synchronize",true,"").once.returns("OK")
    assert_nothing_raised do
      @model.save
    end
  end

  def test_synchronize_error
    @model.actions[:synchronize] = true
    @model.actions[:synchronize_utc] = true
    YastService.stubs(:Call).with("YaPI::NTP::Synchronize",true,"").once.returns("No server defined")
    assert_raise(NtpError.new "No server defined") do
      @model.save
    end
  end  

  def test_synchronize_timeout
    @model.actions[:synchronize] = true
    @model.actions[:synchronize_utc] = true
    msg_mock = mock()
    msg_mock.stubs(:error_name).returns("org.freedesktop.DBus.Error.NoReply")
    msg_mock.stubs(:params).returns(["test","test"])
    YastService.stubs(:Call).with("YaPI::NTP::Synchronize",true,"").once.raises(DBus::Error,msg_mock)

    assert_nothing_raised do
      @model.save
    end
  end  

  def test_unavailable_NTP
    YastService.stubs(:Call).with("YaPI::NTP::Available").once.returns(false)
    assert Ntp.find.actions[:ntp_server]
  end
end
