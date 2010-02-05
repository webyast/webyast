#
# test 'Repository' model
#

require File.join(File.dirname(__FILE__), "..", "test_helper")
require File.join(File.dirname(__FILE__), "..", "packagekit_stub")

require 'repository'

class RepositoryTest < ActiveSupport::TestCase

#  TODO FIXME: there seems to be a bug in PackageKit stubbing,
#  it works only at the first call then it hangs :-(
#  so this test can be run only if one test is uncommented
#  and running just this test file, not the whole test suite
#  (because it interferes with the patches test):
#    rake test:units TEST=test/unit/repository_test.rb
#
#  def setup
#    @pk_stub = PackageKitStub.new
#
#    @results = Array.new
#    @results << PackageKitResult.new("factory-oss", "FACTORY-OSS", "true")
#    @results << PackageKitResult.new("factory-non-oss", "FACTORY-NON-OSS", "false")
#
#    signal = "RepoDetail"
#    @pk_stub.run signal, @results
#  end
#
#  def test_repository_index
#    repos = Repository.find(:all)
#
#    assert_equal repos.size, 2
#    assert_equal repos.first.name, "FACTORY-OSS"
#  end
#
#
#  def test_non_existing_repo
#    repos = Repository.find('dummy_repo')
#    assert repos.size.zero?
#  end
#
#  def test_one_repo
#    repos = Repository.find('factory-oss')
#    assert_equal 1, repos.size
#  end
  
end
