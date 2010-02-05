#
# test 'Repository' model
#

require File.join(File.dirname(__FILE__), "..", "test_helper")
require File.join(File.dirname(__FILE__), "..", "packagekit_stub")

require 'repository'

class RepositoryTest < ActiveSupport::TestCase

  def setup
    @pk_stub = PackageKitStub.new

    # stub:    @transaction_iface.GetRepoList(...)
    @transaction_iface.stubs(:GetRepoList).returns(true)

    @results = Array.new
    @results << PackageKitResult.new("factory-oss", "FACTORY-OSS", "true")
    @results << PackageKitResult.new("factory-non-oss", "FACTORY-NON-OSS", "false")

    @signal = "RepoDetail"
  end

  def test_repository_index
    @pk_stub.run @signal, @results
    repos = Repository.find(:all)

    assert_equal repos.size, 2
    assert_equal repos.first.name, "FACTORY-OSS"
  end


  def test_non_existing_repo
    @pk_stub.run @signal, @results
    
    repos = Repository.find('dummy_repo')
    assert repos.size.zero?
  end

  def test_one_repo
    @pk_stub.run @signal, @results
    
    repos = Repository.find('factory-oss')
    assert_equal 1, repos.size
  end
  
end
