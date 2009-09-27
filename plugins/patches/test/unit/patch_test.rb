#
# patch_test.rb
#
# Test 'Patch' model
#
#

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require File.join(File.dirname(__FILE__), "..", "packagekit_stub")
require 'patch'

class PatchTest < ActiveSupport::TestCase

  SERVICE = "org.freedesktop.PackageKit"
  PATH = "/org/freedesktop/PackageKit"
  TRANSACTION = "#{SERVICE}.Transaction"
  TID = 100 # transaction id

  def setup
    #
    # Patch model stubbing
    #
    
    # avoid accessing the rpm db
    Patch.stubs(:mtime).returns(Time.now)

    @pk_stub = PackageKitStub.new
    
  end
  
  def test_available_patches
    results = Array.new
    # Available updates in PackageKit format
    #
    # Format:
    # [ line1, line2, line3 ]
    # line1: <kind>
    # line2: <name>;<id>;<arch>;<repo>
    # line3: <summary>
    #
    results << PackageKitResult.new( 'important', 'update-test-affects-package-manager;847;noarch;updates-test', 'update-test: Test updates for 11.2')
    results << PackageKitResult.new( 'security', 'update-test;844;noarch;updates-test', 'update-test: Test update for 11.2')

    signal = "Package"
    @pk_stub.run signal, results

    patches = Patch.find(:available)
    assert_equal 2, patches.size
    patch = patches.first
    assert_equal "847", patch.resolvable_id

    
  end
  
end
