require 'packagekit'

# Used to stop DBus::Main loop
class PKErrorException < Exception; end
# Used to stop DBus::Main loop
class PKFinishedException < Exception; end

# Model for patches available via package kit
class Patch < PackageKitModule

  attr_accessor   :resolvable_id,
                  :kind,
                  :name,
                  :arch,
                  :repo,
                  :summary

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

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.patch_update do
      xml.tag!(:resolvable_id, @resolvable_id, {:type => "integer"} )
      xml.tag!(:kind, @kind )
      xml.tag!(:name, @name )
      xml.tag!(:arch, @arch )
      xml.tag!(:repo, @repo )
      xml.tag!(:summary, @summary )
    end
  end

  # find patches
  # Patch.find(:available)
  # Patch.find(212)
  def self.find(what)
    if what == :available
      patch_updates = Array.new
      self.execute("GetUpdates", "NONE", "Package") { |line1,line2,line3|
          columns = line2.split ";"
          update = Patch.new(:resolvable_id => columns[1],
                             :kind => line1,
                             :name => columns[0],
                             :arch => columns[2],
                             :repo => columns[3],
                             :summary => line3 )
          patch_updates << update
        }
      return patch_updates
    end
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

  # install an update, based on the PackageKit
  # id
  def self.package_kit_install(pkkit_id)
    ok = true
    system_bus = DBus::SystemBus.instance
    package_kit = system_bus.service("org.freedesktop.PackageKit")
    obj = package_kit.object("/org/freedesktop/PackageKit")
    obj.introspect
    obj_with_iface = obj["org.freedesktop.PackageKit"]
    tid = obj_with_iface.GetTid
    obj_tid = package_kit.object(tid[0])
    obj_tid.introspect
    obj_tid_with_iface = obj_tid["org.freedesktop.PackageKit.Transaction"]
    obj_tid.default_iface = "org.freedesktop.PackageKit.Transaction"

    finished = false
    obj_tid.on_signal("Package") do |line1,line2,line3|
      Rails.logger.debug "  update package: #{line2}"
    end

    obj_tid.on_signal("Error") do |u1,u2|
      raise PKErrorException
    end
    obj_tid.on_signal("Finished") do |u1,u2|
      raise PKFinishedException
    end
    obj_tid_with_iface.UpdatePackages([pkkit_id])

    unless finished
      loop = DBus::Main.new
      loop << system_bus
      begin
        loop.run
      rescue PKErrorException
        finished = true
        ok = false
      rescue PKFinishedException
        finished = true
      end
    end
    obj_with_iface.SuggestDaemonQuit

    return ok
  end


end
