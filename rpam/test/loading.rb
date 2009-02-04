#
# Test loading of rpam
#

$:.unshift "../ext/Rpam"
require 'test/unit'

class LoadTest < Test::Unit::TestCase
  def test_loading
    require 'rpam'
    assert Rpam
  end
end
