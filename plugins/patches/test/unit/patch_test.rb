
require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'patch'

class PatchTest < ActiveSupport::TestCase

  SERVICE = "org.freedesktop.PackageKit"
  PATH = "/org/freedesktop/PackageKit"
  TRANSACTION = "#{SERVICE}.Transaction"

  def setup
    # avoid accessing the rpm db
    Patch.stubs(:mtime).returns(Time.now)

    # We mock all calls needed to access the PackageKit
    # dbus service
    update_result1 = ['important', 'update-test-affects-package-manager;847;noarch;updates-test', 'update-test: Test updates for 11.2']
    update_result2 = ['security', 'update-test;844;noarch;updates-test', 'update-test: Test update for 11.2']

    obj_tid = DBus::ProxyObject.new(DBus::SystemBus.instance, SERVICE, "/104_acdadcdd_data")
    obj_tid.stubs(:introspect).returns(true)

    obj_tid_with_iface = DBus::ProxyObjectInterface.new(obj_tid, TRANSACTION)
    obj_tid_with_iface.stubs(:GetUpdates).with("NONE").returns(true)
    #obj_tid.stubs(:'[]').with(TRANSACTION).returns(obj_tid_with_iface)

    obj_tid[TRANSACTION] = obj_tid_with_iface
    
    #obj_tid.stubs(:'default_iface=').with(TRANSACTION).returns(TRANSACTION)
    obj_tid.stubs(:has_iface?).returns(true)
    
    object = DBus::ProxyObject.new(DBus::SystemBus.instance, SERVICE, PATH)
    object.stubs(:introspect).returns(true)
    

    obj_with_iface = DBus::ProxyObjectInterface.new(object, SERVICE)
    obj_with_iface.stubs(:GetTid).returns([100])
    obj_with_iface.stubs(:SuggestDaemonQuit).returns(true)

    object.stubs(:'[]').with(SERVICE).returns(obj_with_iface)

    DBus::Service.any_instance.stubs(:object).with(PATH).returns(object)
    DBus::Service.any_instance.stubs(:object).with(100).returns(obj_tid)    

    service = DBus::Service.new(SERVICE, DBus::SystemBus.instance)
    service.stubs(:object).with(PATH).returns(object)
    service.stubs(:object).with(100).returns(obj_tid)    

    DBus::SystemBus.instance.stubs(:service).with(SERVICE).returns(service)

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
