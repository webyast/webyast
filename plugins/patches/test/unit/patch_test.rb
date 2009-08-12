
require 'test_helper'
require 'patch'

class PatchTest < ActiveSupport::TestCase

  def setup
    Patch.stubs(:mtime).returns(Time.now)
  end

  def test_available_patches
    patches = Patch.find(:available)
    assert_equal(1, patches.size)

    patch = Patch.find(patches.first.id)
  end
  
end
