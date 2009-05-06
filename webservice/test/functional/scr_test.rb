#
# test/functional/scr_test.rb
#
# This tests lib/scr, the Scr proxy for YaST D-Bus
#
require 'test_helper'

class ScrTest < ActiveSupport::TestCase

  require "lib/scr"

  test "instanciating the scr singleton" do
    assert Scr.instance
  end

end
