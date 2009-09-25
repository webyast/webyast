#
# packagekit_stub.rb
#
# Stubs for PackageKit/D-Bus
#
#

require File.join(File.dirname(__FILE__), "test_helper")

class PackageKitResult
  attr_reader :info, :id, :summary
  
  def initialize info, id, summary
    @info = info
    @id = id
    @summary = summary
  end
  
  def to_dbus
    [ @info.to_s, @id.to_s, @summary.to_s ]
  end
end

class PackageKitStub

  SERVICE = "org.freedesktop.PackageKit"
  PATH = "/org/freedesktop/PackageKit"
  TRANSACTION = "#{SERVICE}.Transaction"
  TID = 42 # (dummy) transaction id

  def initialize

    #
    # PackageKit stubbing
    #
    # We mock all calls needed to access the PackageKit
    # dbus service
    #
    # Reference: http://www.packagekit.org/gtk-doc/index.html
    #
    
    #
    # PackageKit service
    #
    
    # create (dormant) @pk_service
    @pk_service = DBus::Service.new(SERVICE, DBus::SystemBus.instance)

    # stub:     @pk_service = system_bus.service("org.freedesktop.PackageKit")    
    DBus::SystemBus.instance.stubs(:service).with(SERVICE).returns(@pk_service)

    #
    # PackageKit proxy object
    #
    @packagekit_proxy = DBus::ProxyObject.new(DBus::SystemBus.instance, SERVICE, PATH)

    # stub:     @packagekit_proxy = @pk_service.object("/org/freedesktop/PackageKit")
    @pk_service.stubs(:object).with(PATH).returns(@packagekit_proxy)

    # stub:     @packagekit_proxy.introspect
    @packagekit_proxy.stubs(:introspect).returns(true)
    @packagekit_proxy.stubs(:has_iface?).returns(true)

    #
    # PackageKit interface
    #
    @packagekit_iface = DBus::ProxyObjectInterface.new(@packagekit_proxy, SERVICE)
    
    # stub:     @packagekit_iface = @packagekit_proxy["org.freedesktop.PackageKit"]
    @packagekit_proxy[SERVICE] = @packagekit_iface
    
    # stub:     tid = @packagekit_iface.GetTid
    @packagekit_iface.stubs(:GetTid).returns([TID])
        
    #
    # PackageKit transaction proxy
    #
    @transaction_proxy = DBus::ProxyObject.new(DBus::SystemBus.instance, SERVICE, PATH)

    # stub:    @transaction_proxy = @pk_service.object(tid[0])
    @pk_service.stubs(:object).with(TID).returns(@transaction_proxy)

    # stub:    @transaction_proxy.introspect
    @transaction_proxy.stubs(:introspect).returns(true)
    @transaction_proxy.stubs(:has_iface?).returns(true)

    #
    # PackageKit transaction interface
    #
    @transaction_iface = DBus::ProxyObjectInterface.new(@transaction_proxy, TRANSACTION)
    
    # stub:    @transaction_iface = @transaction_proxy["org.freedesktop.PackageKit.Transaction"]
    @transaction_proxy[TRANSACTION] = @transaction_iface

    # stub:     @packagekit_iface.SuggestDaemonQuit
    @packagekit_iface.stubs(:SuggestDaemonQuit).returns(true)

    # stub:    @transaction_iface.GetUpdates("NONE")
    @transaction_iface.stubs(:GetUpdates).with("NONE").returns(true)
    
    # stub:    @transaction_iface.SearchName(...)
    @transaction_iface.stubs(:SearchName).returns(true)

  end # stub !

  # now mock DBus::Main.run to emit "Package" signals on the SystemBus
  # pass it an Array of 'PackageKitResult's
  #
  def run(signal, results)
    # copy to local variables since instance vars are not(!) accessible inside the 'run' block
    pks = @pk_service
    ti = @transaction_iface
    
    # alias 'run' as 'orig_run'
    DBus::Main.class_eval { alias :orig_run :run }
    
    # Now overlay 'run' with our own implementation
    # This will fake a sender (via .emit) sending signals
    # then we call orig_run to process these signals
    #
    # Remark: This might look overly complex but emitting the signals
    #  at PackageKitResult creation does not work. It seems as if the
    #  buffer (socket?) is flushed so the previously emitted signals are
    #  not received when calling 'run'.
    #
    #  So this implementation presents the only working solution: Emitting
    #  the signals from inside a faked 'run' and the processing them by
    #  calling 'orig_run'.
    #
    
    # pass a closure(!) to 'run'
    DBus::Main.send(:define_method, :run) do
      sig = DBus::Signal.new(signal)
      sig.add_param( [ "info", "s" ] )
      sig.add_param( [ "id", "s" ] )
      sig.add_param( [ "summary", "s" ] )
      # this block is executed in DBus::Main context 
      results.each do |result|
	# emit(service, obj, intf, sig, *args)
	DBus::SystemBus.instance.emit(pks, ti.object, ti, sig, *result.to_dbus)
      end
      DBus::SystemBus.instance.emit(pks, ti.object, ti, DBus::Signal.new("Finished"))
      # now call the original 'run' to process the signals we just emitted
      self.orig_run
    end
  end

end # PackageKitStub
