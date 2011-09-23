require 'helper'
require 'ruby-debug'


class PolKitTest < Test::Unit::TestCase
  def test_root
    assert_raises RuntimeError do
      PolKit1::polkit1_check( "org.freedesktop.policykit.read", "root")
    end
  end
     
  def test_unknown_user
    assert_raises RuntimeError do
      PolKit1::polkit1_check( "org.freedesktop.policykit.read", "unknown")
    end
  end
     
end  
