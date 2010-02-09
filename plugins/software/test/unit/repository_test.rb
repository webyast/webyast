#
# test 'Repository' model
#

require File.join(File.dirname(__FILE__), "..", "test_helper")
require File.join(File.dirname(__FILE__), "..", "packagekit_stub")

require 'repository'

class RepositoryTest < ActiveSupport::TestCase

  def setup
    @pkit_stub = PackageKitStub.new
    @transaction, @packagekit = PackageKit.connect

    # Mock 'GetRepoList' by defining it
    m = DBus::Method.new("GetRepoList")
    m.from_prototype("in filter:s")
    @transaction.methods[m.name] = m
    
    @transaction.stubs(:pkit_stub).returns(@pkit_stub)
    class <<@transaction
      def GetRepoList filter
	rset = PackageKitResultSet.new "RepoDetail", :info => :s, :id => :s, :summary => :s
	rset << ["factory-oss", "FACTORY-OSS", "true"]
	rset << ["factory-non-oss", "FACTORY-NON-OSS", "false"]
    
        self.pkit_stub.result = rset
      end
    end

  end

  def test_repository_index
    repos = Repository.find(:all)

    assert_equal 2,repos.size
    assert_equal "FACTORY-OSS", repos.first.name
  end

  # check to_xml producing correct (valid) output
  def test_repository_to_xml
    repo = Repository.new("factory-oss", "FACTORY-OSS", true)

    xml = repo.to_xml
    h = Hash.from_xml xml

    assert_equal "factory-oss", h['repository']['id']
  end

end
