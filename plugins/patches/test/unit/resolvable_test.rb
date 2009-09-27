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
    @pk_stub = PackageKitStub.new
  end

  # (dummy) test 'SearchName'
  # this mostly tests correct stubbing
  def test_resolvable_search
    if false # DISABLED
    results = Array.new
    results << PackageKitResult.new( "info1", "id1", "summary1" )
    results << PackageKitResult.new( "info2", "id2", "summary2" )
    signal = "Package"
    @pk_stub.run signal, results
    count = 0
    Resolvable.execute( "SearchName", ["installed;~devel", "yast2"], signal) do |info,id,summary|
      assert_equal results[count].info, info
      assert_equal results[count].id, id
      assert_equal results[count].summary, summary
      count += 1
    end
    assert_equal results.size, count
  end
  end
  
end
