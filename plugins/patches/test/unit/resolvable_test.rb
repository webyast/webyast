#
# resolvable_test.rb
#
# Test 'Resolvable' model
#
#

require File.join(File.dirname(__FILE__), "..", "test_helper")
require File.join(File.dirname(__FILE__), "..", "packagekit_stub")

class ResolvableTest < ActiveSupport::TestCase
  require 'resolvable'

  def setup
    PackageKitStub.stub!
  end

  def test_resolvable_search
    Resolvable.execute( "SearchName", ["installed;~devel", "yast2"], "Package") do |info,id,summary|
      assert info
      assert id
      assert summary
    end
    
  end
  
end
