#
# Test bad arguments
#

$:.unshift "../ext/Rpam"
require 'test/unit'
require 'rpam'

class LoadTest < Test::Unit::TestCase
  def test_bad_arg
    assert_raise(ArgumentError) { Rpam::authpam() }
    assert_raise(ArgumentError) { Rpam::authpam(nil) }
    assert_raise(TypeError) { Rpam::authpam(1,false) }
    assert_nothing_raised { Rpam::authpam("", "") }
  end
end
