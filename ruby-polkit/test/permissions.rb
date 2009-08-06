$:.unshift "../src"

# Load in the extension
require 'polkit'

require 'test/unit'

class PolKitTest < Test::Unit::TestCase
  def test_root
    assert_equal :auth, PolKit::polkit_check( "org.freedesktop.policykit.read", "root")
  end
  
  def test_nobody
    assert_equal :auth, PolKit::polkit_check( "org.freedesktop.policykit.read", "nobody")
  end
      
  def test_unknown_user
    assert_raise RuntimeError do
      PolKit::polkit_check( "org.freedesktop.policykit.read", "unknown")
    end
  end
      
  def test_unknown_action
    assert_raise RuntimeError do
      PolKit::polkit_check( "foo.bar", "root")
    end
  end
      
  def test_user
    begin
      user = "user"
      assert PolKit::polkit_check( "opensuse.yast.scr.read.sysconfig.clock.timezone", user)
    rescue RuntimeError
      $stderr.puts "\n*** Please edit and set local user"
      assert false
    end
  end
end  
