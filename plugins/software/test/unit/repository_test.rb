#
# test 'Repository' model
#

require File.join(File.dirname(__FILE__), "..", "test_helper")
require File.join(File.dirname(__FILE__), "..", "packagekit_stub")

require 'repository'

class RepositoryTest < ActiveSupport::TestCase

  def setup
    @pk_stub = PackageKitStub.new
    @transaction, @packagekit = PackageKit.connect
    
    rset = PackageKitResultSet.new "Package", :info => :s, :id => :s, :summary => :s
    rset << ["factory-oss", "FACTORY-OSS", "true"]
    rset << ["factory-non-oss", "FACTORY-NON-OSS", "false"]
    
    @pk_stub.result = rset
    
    # Mock 'GetRepoList' by defining it
    m = DBus::Method.new("GetRepoList")
    m.from_prototype("in filter:s")
    @transaction.methods[m.name] = m
    class <<@transaction
      def GetRepoList filter
	# dummy !
      end
    end

  end

  def test_repository_index
    repos = Repository.find(:all)

    assert_equal repos.size, 2
    assert_equal repos.first.name, "FACTORY-OSS"
  end
  
end
