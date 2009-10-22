require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

require 'system'

class SystemTest < ActiveSupport::TestCase

  def setup    
    @model = System.instance
    @model.stubs(:hal_power_management).with(:reboot).returns(true)
    @model.stubs(:hal_power_management).with(:shutdown).returns(true)
  end

  def test_actions
    assert_not_nil @model.actions
    assert_instance_of(Hash, @model.actions, "action() returns Hash")
  end

  def test_reboot
    ret = @model.reboot
    assert ret
    assert @model.actions[:reboot]
  end

  def test_shutdown
    ret = @model.shutdown
    assert ret
    assert @model.actions[:shutdown]
  end

end
