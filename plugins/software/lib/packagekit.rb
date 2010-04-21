#--
# Copyright (c) 2009-2010 Novell, Inc.
# 
# All Rights Reserved.
# 
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License
# as published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
# 
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#++

#
# Module for communication with PackageKit via D-Bus
#

require "dbus"
require 'socket'
require 'thread'

require 'exceptions'

class PackageKitError < BackendException
  def initialize(description)
    @description = description
    super("PackageKit error")
  end

  def to_xml
    xml = Builder::XmlMarkup.new({})
    xml.instruct!

    xml.error do
      xml.type "PACKAGEKIT_ERROR"
      xml.description @description
    end
  end
end

class PackageKit

  private
  def self.dbusloop proxy, error = ''
    dbusloop = DBus::Main.new
    proxy.on_signal("ErrorCode") do |u1,u2| 
      error_string = "#{u1}: #{u2}"
      Rails.logger.error error_string
      dbusloop.quit
      error << error_string if error.empty?
    end
    
    proxy.on_signal("RepoSignatureRequired") do |u1,u2,u3,u4,u5,u6,u7,u8| 
      error_string = "Repository #{u2} needs to be signed"
      Rails.logger.error error_string
      dbusloop.quit
      error << error_string if error.empty?
    end
    proxy.on_signal("Finished") {|u1,u2| dbusloop.quit }
    dbusloop
  end
  
  public
  #
  # PackageKit.connect
  #
  # connect to PackageKit and create Transaction proxy
  #
  # return Array of <transaction proxy>,<packagekit interface>,<transaction 
  #
  # Reference: http://www.packagekit.org/gtk-doc/index.html
  #

  def self.connect
    system_bus = DBus::SystemBus.instance
    # connect to PackageKit service via SystemBus
    pk_service = system_bus.service("org.freedesktop.PackageKit")
    
    # Create PackageKit proxy object
    packagekit_proxy = pk_service.object("/org/freedesktop/PackageKit")

    # learn about object
    packagekit_proxy.introspect
    
    # use the (generic) 'PackageKit' interface
    packagekit_iface = packagekit_proxy["org.freedesktop.PackageKit"]
    
    # get transaction id via this interface
    tid = packagekit_iface.GetTid
    
    # retrieve transaction (proxy) object
    transaction_proxy = pk_service.object(tid[0])
    transaction_proxy.introspect
    
    # use the 'Transaction' interface
    transaction_iface = transaction_proxy["org.freedesktop.PackageKit.Transaction"]
    transaction_proxy.default_iface = "org.freedesktop.PackageKit.Transaction"

    [transaction_iface, packagekit_iface]
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

  #
  # Execute PackageKit transaction method
  #
  # method: method to execute
  # args: arguments to method
  # signal: signal to intercept (usually "Package") (optional)
  # bg_stat: BackgroundStatus object for reporting progress (optional)
  # block: block to run on signal (optional)
  #
  def self.transact(method, args, signal = nil, bg_stat = nil, &block)
    begin
      transaction_iface, packagekit_iface = self.connect
    
      proxy = transaction_iface.object
    
      error = ''

      # set the custom signal handler if set
      proxy.on_signal(signal.to_s, &block) if !signal.blank? && block_given?

      if bg_stat
        proxy.on_signal("StatusChanged") do |s|
          Rails.logger.debug "PackageKit progress: StatusChanged: #{s}"
          bg_stat.status = s
        end

        proxy.on_signal("ProgressChanged") do |p1, p2, p3, p4|
          Rails.logger.debug "PackageKit progress: ProgressChanged: #{p1}%"
          # 101% means no progress/subprogress available
          bg_stat.progress = p1 < 101 ? p1 : -1
          bg_stat.subprogress = p2 < 101 ? p2 : -1
        end
      end

      dbusloop = self.dbusloop proxy, error

      dbusloop << proxy.bus

      # Do the call only when all signal handlers are in place,
      # otherwise Finished can arrive early and dbusloop will never
      # quit, bnc#561578
      # call it after creating the DBus loop (bnc#579001)
      result = transaction_iface.send(method.to_sym, *args)

      # run the main loop, process the incoming signals
      dbusloop.run

      packagekit_iface.SuggestDaemonQuit

      raise PackageKitError.new(error) unless error.blank?

    rescue DBus::Error => dbus_error
      # check if it is a known error
      raise ServiceNotAvailable.new('PackageKit') if dbus_error.message =~ /org.freedesktop.DBus.Error.ServiceUnknown/
      # otherwise rethrow
      raise dbus_error
    rescue Exception => e
      raise e
    end
    
    result
  end

  # install an update, based on the PackageKit
  # id ("<name>;<id>;<arch>;<repo>")
  #
  def self.install(pk_id)
    ok = true
    transaction_iface, packagekit_iface = self.connect

    proxy = transaction_iface.object
    proxy.on_signal("Package") do |line1,line2,line3|
      Rails.logger.debug "  update package: #{line2}"
    end

    error = ''
    dbusloop = self.dbusloop proxy, error
    dbusloop << proxy.bus

    proxy.on_signal("Error") do |u1,u2|
      ok = false
      dbusloop.quit
    end
    if transaction_iface.methods["UpdatePackages"] && # catch mocking
       transaction_iface.methods["UpdatePackages"].params.size == 2 &&
       transaction_iface.methods["UpdatePackages"].params[0][0] == "only_trusted"
      #PackageKit of 11.2
      transaction_iface.UpdatePackages(true,  #only_trusted
                                                              [pk_id])
    else
      #PackageKit older versions like SLES11
      transaction_iface.UpdatePackages([pk_id])
    end

    dbusloop.run
    packagekit_iface.SuggestDaemonQuit

    ok &= error.blank?

    return ok
  end

end
