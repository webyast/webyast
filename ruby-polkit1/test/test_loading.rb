#
# Test loading of polkit
#
require 'helper'

class LoadTest < Test::Unit::TestCase
  def test_loading
    require 'polkit1'
    assert PolKit1
  end
end
