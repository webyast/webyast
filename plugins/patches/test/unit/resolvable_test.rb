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
    @transaction, @packagekit = PackageKit.connect
    
    rset = PackageKitResultSet.new "Package", :info => :s, :id => :s, :summary => :s
    rset << ["info1", "id1", "summary1"]
    rset << [:info2, :id2, :summary2]
    
    @pk_stub.result = rset
    
    # stub:    @transaction_iface.SearchName(...)
    @transaction_iface.stubs(:SearchName).returns(true)
  end

  # (dummy) test 'SearchName'
  # this mostly tests correct stubbing
  def test_resolvable_search
    count = 0
    PackageKit.transact( "SearchName", ["installed;~devel", "yast2"], "Package") do |info,id,summary|
      assert_equal results[count].info, info
      assert_equal results[count].id, id
      assert_equal results[count].summary, summary
      count += 1
    end
    assert_equal results.size, count
  end
  
end
