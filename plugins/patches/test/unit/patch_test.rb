
require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
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

    # Available updates in PackageKit format
    #
    # Format:
    # [ line1, line2, line3 ]
    # line1: <kind>
    # line2: <name>;<id>;<arch>;<repo>
    # line3: <summary>
    #
    update_result1 = ['important', 'update-test-affects-package-manager;847;noarch;updates-test', 'update-test: Test updates for 11.2']
    update_result2 = ['security', 'update-test;844;noarch;updates-test', 'update-test: Test update for 11.2']


    #
    # PackageKit stubbing
    #
    # We mock all calls needed to access the PackageKit
    # dbus service
    #
    
    # Service object with arbitrary transaction id
    obj_tid = DBus::ProxyObject.new(DBus::SystemBus.instance, SERVICE, "/104_acdadcdd_data")
    # no introspection needed
    obj_tid.stubs(:introspect).returns(true)
    # provides interface
    obj_tid.stubs(:has_iface?).returns(true)

    # Transaction interface
    obj_tid_with_iface = DBus::ProxyObjectInterface.new(obj_tid, TRANSACTION)
    # provides 'GetUpdates' method
    obj_tid_with_iface.stubs(:GetUpdates).with("NONE").returns(true)

    # allow Array-like access to interface
    obj_tid[TRANSACTION] = obj_tid_with_iface
    
    # Create PackageKit object stub
    object = DBus::ProxyObject.new(DBus::SystemBus.instance, SERVICE, PATH)
    object.stubs(:introspect).returns(true)
    
    # Create interface
    obj_with_iface = DBus::ProxyObjectInterface.new(object, SERVICE)
    
    # Stub a transaction ID
    obj_with_iface.stubs(:GetTid).returns([TID])
    obj_with_iface.stubs(:SuggestDaemonQuit).returns(true)

    # object[SERVICE] returns interface
    object.stubs(:'[]').with(SERVICE).returns(obj_with_iface)

    # allow access to PackageKit and Transaction via Service
    DBus::Service.any_instance.stubs(:object).with(PATH).returns(object)
    DBus::Service.any_instance.stubs(:object).with(TID).returns(obj_tid)    

    # Duplicate ??
    service = DBus::Service.new(SERVICE, DBus::SystemBus.instance)
    service.stubs(:object).with(PATH).returns(object)
    service.stubs(:object).with(TID).returns(obj_tid)    

    DBus::SystemBus.instance.stubs(:service).with(SERVICE).returns(service)
    
    #
    # mix Patch and PackageKit mocking
    #

    # emit updates
    
    DBus::Main.send(:define_method, :run) do
      DBus::SystemBus.instance.emit(service, obj_tid, obj_tid_with_iface, DBus::Signal.new("Packages"), update_result1)
      DBus::SystemBus.instance.emit(service, obj_tid, obj_tid_with_iface, DBus::Signal.new("Packages"), update_result2)
      @buses.each do |socket, bus|
      end
      return true
    end
    
  end

  def test_available_patches
    patches = Patch.find(:available)
    #assert_equal(2, patches.size)
    #patch = patches.first
    #assert_equal("847", patch.resolvable_id)

    
  end
  
end
