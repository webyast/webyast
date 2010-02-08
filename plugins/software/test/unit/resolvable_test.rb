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
    
    # Mock 'GetUpdates' by defining it
    m = DBus::Method.new("SearchName")
    m.from_prototype("in repos:s, in name:s")
    @transaction.methods[m.name] = m
    class <<@transaction
      def SearchName repos, name
	# dummy !
      end
    end
  end

  # (dummy) test 'SearchName'
  # this mostly tests correct stubbing
  def test_resolvable_search
    count = 0
    results = @pk_stub.result
    PackageKit.transact( "SearchName", ["installed;~devel", "yast2"], "Package") do |info,id,summary|
      assert_equal results[count][0], info
      assert_equal results[count][1], id
      assert_equal results[count][2], summary
      count += 1
    end
    assert_equal results.size, count
  end
  
end
