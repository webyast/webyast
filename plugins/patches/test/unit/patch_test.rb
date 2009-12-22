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

  SCRIPT_OUTPUT_ERROR = [
    '<?xml version="1.0" encoding="UTF-8"?><background_status><status>running</status><progress type="integer">0</progress><subprogress type="integer">-1</subprogress></background_status>',
    '<?xml version="1.0" encoding="UTF-8"?><background_status><status>setup</status><progress type="integer">0</progress><subprogress type="integer">-1</subprogress></background_status>',
    '<?xml version="1.0" encoding="UTF-8"?><background_status><status>query</status><progress type="integer">0</progress><subprogress type="integer">-1</subprogress></background_status>',
    '<?xml version="1.0" encoding="UTF-8"?><background_status><status>refresh-cache</status><progress type="integer">0</progress><subprogress type="integer">-1</subprogress></background_status>',
    '<?xml version="1.0" encoding="UTF-8"?><background_status><status>refresh-cache</status><progress type="integer">9</progress><subprogress type="integer">-1</subprogress></background_status>',
    '<?xml version="1.0" encoding="UTF-8"?><error><type>PACKAGEKIT_ERROR</type><description>gpg-failure: Signature verification for Repository Factory_(Non-OSS) failed</description></error>'
  ]

  def test_available_patches_background_mode
    Patch.stubs(:open_subprocess).returns(nil)
    Patch.stubs(:read_subprocess).returns(*SCRIPT_OUTPUT_ERROR)

    # return EOF when all lines are read
    Patch.stubs(:eof_subprocess?).returns(*(Array.new(SCRIPT_OUTPUT_ERROR.size, false) << true))

    # note: Patch.find(:available, {:background => true})
    # cannot be used here, Threading support in test mode doesn't work :-(
    patches = Patch.subprocess_find(:available)

    assert_equal PackageKitError, patches.class
  end
  
end
