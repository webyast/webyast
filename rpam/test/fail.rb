#
# Test failed authentication
#

$:.unshift "../ext/Rpam"
require 'test/unit'
require 'rpam'

class LoadTest < Test::Unit::TestCase
  def test_auth_fail
    assert !Rpam::authpam("","")
  end
end
