require 'test_helper'

require 'system'

class SystemTest < ActiveSupport::TestCase

  def setup    
    @model = System.instance
  end


  def test_actions
    assert_instance_of(Hash, @model.actions, "action() returns Hash")
  end


end
