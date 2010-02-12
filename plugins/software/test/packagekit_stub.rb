#
# packagekit_stub.rb
#
# Stubs for PackageKit/D-Bus
#
# See http://en.opensuse.org/YaST/Web/Development/Testing/PackageKit
#

require File.join(File.dirname(__FILE__), "test_helper")
require File.expand_path( File.join("test","dbus_stub"), RailsParent.parent )


#
# A result set as send from PackageKit
# all members of this set have the same signal
#

class PackageKitResultSet

  attr_reader :signal, :signature, :elements

  #
  # Create a PackageKitResultSet
  #
  # PackageKitResultSet.new <signal>, <signature-as-hash>
  #
  # (Since a trailing Hash can be passed without enclosing {}'s, it looks like a varargs call)
  #
  # Example:
  #   set = PackageKitResultSet.new "Package", :info => :s, :id => :s, :summary => :s
  #
  # Now add results to the set. Each result is an Array with values according to the signature
  #
  #   set << ["info1", "id1", "summary1"]
  #
  # :s-type arguments can be passed as strings or symbols
  #
  #   set << [:info2, :id2, "summary2"]
  #
  
  def initialize signal, signature
    @signal = signal
    @signature = signature
    @elements = []
  end
  
  def << items
    raise "Wrong number of items" unless items.size == @signature.size
    @elements << (items.collect! { |v| v.to_s } )
  end
  
  def size
    @elements.size
  end
  
  def [] idx
    @elements[idx]
  end
end


class PackageKitStub

  @@first = true
  
  SERVICE = "org.freedesktop.PackageKit"
  PATH = "/org/freedesktop/PackageKit"
  TRANSACTION = "#{SERVICE}.Transaction"
  TID = 42 # (dummy) transaction id

  #
  # Create stubbed PackageKit service instance
  #
  #
  
  def initialize

    # create (dormant) @pk_service
    @pk_stub = DBusStub.new :system, SERVICE
    @pk_service = @pk_stub.service
    
    @packagekit_proxy, @packagekit_iface = @pk_stub.proxy PATH, SERVICE
    
    # stub:     tid = @packagekit_iface.GetTid
    @packagekit_iface.stubs(:GetTid).returns([TID])
        
    # stub:     @packagekit_iface.SuggestDaemonQuit
    @packagekit_iface.stubs(:SuggestDaemonQuit).returns(true)


    # stub:    @transaction_proxy = @pk_service.object(tid[0])
    @pk_service.stubs(:object).with(TID).returns(@packagekit_proxy)

    #
    # PackageKit transaction interface
    #
    @transaction_iface = @pk_stub.interface @packagekit_proxy, TRANSACTION
    
    if @@first
      @@first = false

      # alias 'run' as 'orig_run'
      DBus::Main.class_eval { alias :orig_run :run }
      
      # pass a dummy closure to run, see 'def result=' below
      DBus::Main.send(:define_method, :run) do
	return
      end

      ObjectSpace.define_finalizer(self, lambda do |id|
				      DBus::Main.send(:undef_method, :run)
				      DBus::Main.class_eval { alias :run :orig_run }
				    end)
    end # if @@first
  end # initialize
  
  def result
    @result_set
  end
  
  def result= result_set
    
    # create the signal from the signature
    
    signal = DBus::Signal.new(result_set.signal)
    result_set.signature.each do |k,v|
      signal.add_param( [ k.to_s, v.to_s ] )
    end

    # copy to local variables since instance vars are not(!) accessible inside the 'run' block
    stub = @pk_stub
    bus = @pk_stub.bus
    service = @pk_service
    iface_t = @transaction_iface
    
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
      
    DBus::Main.send(:define_method, :run) do
      result_set.elements.each do |result|
	# emit(service, obj, intf, sig, *args)
	bus.emit(service, iface_t.object, iface_t, signal, *result)
      end
      bus.emit(service, iface_t.object, iface_t, DBus::Signal.new("Finished"))
	
      # now call the original 'run' to process the signals we just emitted
      self.orig_run
    end
    
    @result_set = result_set

  end
  
end # PackageKitStub
