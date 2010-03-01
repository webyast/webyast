#
# test 'Repository' model
#

require File.join(File.dirname(__FILE__), "..", "test_helper")
require File.join(File.dirname(__FILE__), "..", "packagekit_stub")

require 'repository'

# make the private method available for testing
class Repository
  public :read_from_file
end


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

      def RepoSetData id, key, value
        return true
      end

      def RepoEnable id, value
        return true
      end

    end

    # don't read system *.repo files
    Repository.any_instance.stubs(:read_file).returns(nil)
  end

  def test_repository_index
    repos = Repository.find(:all)

    assert_equal 2,repos.size
    assert_equal "FACTORY-OSS", repos.first.name
  end

  def test_repository_details
    repos = Repository.find('factory-oss')

    assert_equal 1,repos.size
    assert_equal "FACTORY-OSS", repos.first.name
  end

  def test_repository_create

    assert_nothing_raised do
      repo = Repository.new("factory-oss-new", "FACTORY-OSS-NEW", true)

      repo.enabled = false
      repo.autorefresh = false
      repo.name = 'new name'
      repo.url = 'http://test.com/repo'

      repos = Repository.find(:all)
      Repository.expects(:find).with(:all).returns(repos)

      # ensure that 'add' is called here, not 'url' for updating an existing repo!
      PackageKit.expects(:transact).with('RepoSetData', ["factory-oss-new", "add", repo.url])
      # ensure that all properties are updated
      PackageKit.expects(:transact).with('RepoEnable',  ["factory-oss-new", repo.enabled])
      PackageKit.expects(:transact).with('RepoSetData', ["factory-oss-new", "prio", repo.priority.to_s])
      PackageKit.expects(:transact).with('RepoSetData', ["factory-oss-new", "refresh", repo.autorefresh.to_s])
      PackageKit.expects(:transact).with('RepoSetData', ["factory-oss-new", "keep", repo.keep_packages.to_s])
      PackageKit.expects(:transact).with('RepoSetData', ["factory-oss-new", "name", repo.name])

      assert repo.save
    end
  end

  def test_repository_update

    repo = Repository.find('factory-oss').first

    repo.enabled = false
    repo.autorefresh = false
    repo.name = 'new name'
    repo.url = 'ftp://new.url.com/repo'

    repos = Repository.find(:all)
    Repository.expects(:find).with(:all).returns(repos)

    # ensure that 'url' is called here, not 'add' for adding a new repo!
    PackageKit.expects(:transact).with('RepoSetData', ["factory-oss", "url", repo.url])
    # ensure that all properties are updated
    PackageKit.expects(:transact).with('RepoEnable',  ["factory-oss", repo.enabled])
    PackageKit.expects(:transact).with('RepoSetData', ["factory-oss", "prio", repo.priority.to_s])
    PackageKit.expects(:transact).with('RepoSetData', ["factory-oss", "refresh", repo.autorefresh.to_s])
    PackageKit.expects(:transact).with('RepoSetData', ["factory-oss", "keep", repo.keep_packages.to_s])
    PackageKit.expects(:transact).with('RepoSetData', ["factory-oss", "name", repo.name])

    assert_nothing_raised do
      assert repo.save
    end
  end

  def test_repository_destroy
    repo = Repository.find('factory-oss').first

    PackageKit.expects(:transact).with('RepoSetData', ['factory-oss', 'remove', 'NONE']).returns(true)

    assert_nothing_raised do
      assert repo.destroy
    end
  end

  # check to_xml producing correct (valid) output
  def test_repository_to_xml
    repo = Repository.new("factory-oss", "FACTORY-OSS", true)

    xml = repo.to_xml
    h = Hash.from_xml xml

    assert_equal "factory-oss", h['repository']['id']
  end

  def test_repository_to_json
    jsn = Repository.new("factory-oss", "FACTORY-OSS", true).to_json

    repo_from_json = ActiveSupport::JSON.decode(jsn)

    assert_equal repo_from_json, {"repository"=>{"name"=>"FACTORY-OSS", "autorefresh"=>true, "url"=>nil,
        "priority"=>99, "id"=>"factory-oss", "enabled"=>true, "keep_packages"=>false}}
  end

  def test_repo_file_parsing
    repo = Repository.new("factory-oss", "FACTORY-OSS", true)

    fname = File.join(File.dirname(__FILE__), '..', 'fixtures', 'repos.d', 'Ruby.repo')
    repo.read_from_file fname

    # keep the alias, name and priority which was read from PackageKit
    assert_equal 'FACTORY-OSS', repo.name
    assert_equal 'factory-oss', repo.id
    assert_equal true, repo.enabled

    # check the read values
    assert_equal 120, repo.priority
    assert_equal false, repo.autorefresh
    assert_equal 'http://download.opensuse.org/repositories/devel:/languages:/ruby:/extensions/openSUSE_Factory', repo.url

    # use the default value if the key is missing
    assert_equal false, repo.keep_packages
  end
end
