require "dbus"
require 'socket'
require 'thread'

# Used to stop DBus::Main loop
class PKErrorException < Exception; end
# Used to stop DBus::Main loop
class PKFinishedException < Exception; end

# Model for packages available via package kit
class Package

  attr_accessor   :resolvable_id,
                  :name,
                  :version

  def initialize()

  end

  def to_xml( options = {} )
    xml = options[:builder] ||= Builder::XmlMarkup.new(options)
    xml.instruct! unless options[:skip_instruct]

    xml.patch_update do
      xml.tag!(:resolvable_id, @resolvable_id, {:type => "integer"} )
      xml.tag!(:name, @name )
      xml.tag!(:version, @version )
    end
  end

  def to_json( options = {} )
    hash = Hash.from_xml(to_xml())
    return hash.to_json
  end

  def self.find()
    begin
      package_list = Array.new
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

      obj_tid_with_iface.GetPackages("installed")

      obj_tid.on_signal("Package") do |line1,line2,line3|
        columns = line2.split ";"
        package_list << Package.new(:resolvable_id => line2,
                                    :version => columns[1],
                                    :name => columns[0]
                                   )
      end

      obj_tid.on_signal("Error") do |u1,u2|
        raise PKErrorException
      end
      obj_tid.on_signal("Finished") do |u1,u2|
        raise PKFinishedException
      end

      if package_list.empty?
        loop = DBus::Main.new
        loop << system_bus
        begin
          loop.run
        rescue PKErrorException
        rescue PKFinishedException
        end
      end
 		rescue Exception
      return -1
	  end

    obj_with_iface.SuggestDaemonQuit

    package_list
  end
end
