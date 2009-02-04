#
# Test loading of polkit
#

$:.unshift "../src"
require 'test/unit'

class LoadTest < Test::Unit::TestCase
  def test_loading
    require 'polkit'
    assert PolKit
  end
end
