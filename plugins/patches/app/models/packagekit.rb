require "dbus"
require 'socket'
require 'thread'

# Used to stop DBus::Main loop
class PKErrorException < Exception; end
# Used to stop DBus::Main loop
class PKFinishedException < Exception; end

# Model for patches available via package kit
class PackageKitModule

  def id
    @resolvable_id
  end

  def id=(id_val)
    @resolvable_id = id_val
  end

  # returns the modification time of
  # the patch status, which you can use
  # for cache policy purposes
  def self.mtime
    # we look for the most recent (max) modification time
    # of either the package database or libzypp cache files
    [ File.stat("/var/lib/rpm/Packages").mtime,
      File.stat("/var/cache/zypp/solv").mtime,
      * Dir["/var/cache/zypp/solv/*/solv"].map{ |x| File.stat(x).mtime } ].max
  end

  # default constructor
  def initialize(attributes)
    attributes.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end

  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end

  # find patches
  # Patch.find(:available)
  # Patch.find(212)
  def self.execute(method, args, signal, &block)
    patch_updates = []
    system_bus = DBus::SystemBus.instance
    package_kit = system_bus.service("org.freedesktop.PackageKit")
    obj = package_kit.object("/org/freedesktop/PackageKit")
    #logger.debug obj.inspect
    obj.introspect
    obj_with_iface = obj["org.freedesktop.PackageKit"]
    tid = obj_with_iface.GetTid
    obj_tid = package_kit.object(tid[0])
    obj_tid.introspect
    obj_tid_with_iface = obj_tid["org.freedesktop.PackageKit.Transaction"]
    obj_tid.default_iface = "org.freedesktop.PackageKit.Transaction"

    obj_tid.on_signal(signal.to_s, &block)

    obj_tid.on_signal("Error") do |u1,u2|
      raise PKErrorException
    end
    obj_tid.on_signal("Finished") do |u1,u2|
      raise PKFinishedException
    end

    obj_tid_with_iface.send(method.to_sym, *args)

    if patch_updates.empty?
      loop = DBus::Main.new
      loop << system_bus
      begin
	loop.run
      rescue PKErrorException
        puts "PKErrorException"
      rescue PKFinishedException
        puts "PKFinished"
      end
    end

    obj_with_iface.SuggestDaemonQuit
    return patch_updates
  end

  # installs this
  def install
    self.class.install(id)
  end

  # Patch.install(patch)
  # Patch.install(id)
  def self.install(patch)
    if patch.is_a?(Patch)
      update_id = "#{patch.name};#{patch.resolvable_id};#{patch.arch};#{@patch.repo}"
      Rails.logger.debug "Install Update: #{update_id}"
      self.package_kit_install(update_id)
    else
      # if is not an object, assume it is an id
      patch_id = patch
      patch = Patch.find(patch_id)
      raise "Can't install update #{patch_id} because it does not exist" if patch.nil? or not patch.is_a?(Patch)
      self.install(patch)
    end
  end
end
