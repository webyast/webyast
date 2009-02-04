$:.unshift "../src"

# Load in the extension
require 'polkit'

require 'test/unit'

class PolKitTest < Test::Unit::TestCase
  def test_root
    assert PolKit::polkit_check( "org.freedesktop.policykit.read", "root") == :auth
  end
  
  def test_nobody
    assert PolKit::polkit_check( "org.freedesktop.policykit.read", "nobody") == :auth
  end
      
  def test_unknown_user
    begin
      PolKit::polkit_check( "org.freedesktop.policykit.read", "unknown")
      assert false # not reached
    rescue Exception => e
      assert true
    end
  end
      
  def test_unknown_action
    begin
      PolKit::polkit_check( "foo.bar", "root")
      assert false # not reached
    rescue Exception => e
      assert true
    end
  end
      
  def test_user
    begin
      user = "user"
      assert PolKit::polkit_check( "opensuse.yast.scr.read.sysconfig.clock.timezone", user)
    rescue RuntimeError
      $stderr.puts "Please edit and set local user"
      assert false
    end
  end
end  
