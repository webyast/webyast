require "dbus"
require 'socket'
require 'thread'

# Model for patches available via package kit
class Resolvable

  attr_accessor   :resolvable_id,
                  :kind,
                  :name,
		  :version,
                  :arch,
                  :repo,
                  :summary

private
  def self.packagekit_connect

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

    dbusloop = DBus::Main.new
    dbusloop << system_bus

    [dbusloop, obj_tid, obj_with_iface, obj_tid_with_iface]
  end

public

  # default constructor
  def initialize(attributes)
    attributes.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end

  def id
    @resolvable_id
  end

  def id=(id_val)
    @resolvable_id = id_val
  end

  # get xml representation of instance
  # tag: name of toplevel tag (i.e. :package)
  #
  def to_xml( tag, options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.send tag.to_sym do
      xml.tag!(:resolvable_id, @resolvable_id, {:type => "integer"} )
      xml.tag!(:kind, @kind )
      xml.tag!(:name, @name )
      xml.tag!(:version, @version )
      xml.tag!(:arch, @arch )
      xml.tag!(:repo, @repo )
      xml.tag!(:summary, @summary )
    end

  end
  
  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end

  # returns the modification time of the resolvable
  # which you can use for cache policy purposes
  def self.mtime
    # we look for the most recent (max) modification time
    # of either the package database or libzypp cache files
    [ File.stat("/var/lib/rpm/Packages").mtime,
      File.stat("/var/cache/zypp/solv").mtime,
      * Dir["/var/cache/zypp/solv/*/solv"].map{ |x| File.stat(x).mtime } ].max
  end

  # find patches
  # Patch.find(:available)
  # Patch.find(212)
  def self.execute(method, args, signal, &block)
    patch_updates = []

    dbusloop, obj_tid, obj_with_iface, obj_tid_with_iface = self.packagekit_connect
    
    obj_tid.on_signal(signal.to_s, &block)
    obj_tid.on_signal("Error") {|u1,u2| loop.quit }
    obj_tid.on_signal("Finished") {|u1,u2| loop.quit }

    obj_tid_with_iface.send(method.to_sym, *args)
    dbusloop.run

    obj_with_iface.SuggestDaemonQuit
    return patch_updates
  end

  # install an update, based on the PackageKit
  # id
  def self.package_kit_install(pkkit_id)
    ok = true
    mainloop, obj_tid, obj_with_iface, obj_tid_with_iface = self.packagekit_connect

    obj_tid.on_signal("Package") do |line1,line2,line3|
      Rails.logger.debug "  update package: #{line2}"
    end

    dbusloop = DBus::Main.new
    dbusloop << system_bus

    obj_tid.on_signal("Finished") {|u1,u2| loop.quit }
    obj_tid.on_signal("Error") do |u1,u2|
      ok = false
      dbusloop.quit
    end
    obj_tid_with_iface.UpdatePackages([pkkit_id])

    dbusloop.run
    obj_with_iface.SuggestDaemonQuit

    return ok
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
