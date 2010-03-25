#
# packagekit_test.rb
#
# Test 'PackageKit' class
#
#

require File.join(File.dirname(__FILE__), "..", "test_helper")
require File.join(File.dirname(__FILE__), "..", "packagekit_stub")

class PackageKitTest < ActiveSupport::TestCase
  require 'packagekit'

  def setup
    @pk_stub = PackageKitStub.new
    @transaction, @packagekit = PackageKit.connect
    
    rset = PackageKitResultSet.new "Package", :info => :s, :id => :s, :summary => :s
    rset << ["info1", "id1", "summary1"]
    rset << [:info2, :id2, :summary2]
    
    @pk_stub.result = rset
  end

  def test_connect
    assert @pk_stub
    assert @transaction
    assert @packagekit
  end
  
  def test_transact
    @transaction.stubs(:GetUpdates).with("NONE").returns(true)
    
    result = PackageKit.transact "GetUpdates", "NONE"
    assert result
  end
  
  def test_install
    @transaction.stubs(:UpdatePackages).returns(true)

    result = PackageKit.install :id1
    assert result
  end
end
