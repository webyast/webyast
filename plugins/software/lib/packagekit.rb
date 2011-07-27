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
  attr_reader :description

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
  def self.improve_error(dbus_error)
    # check if it is a known error
    if dbus_error.respond_to?('name') && dbus_error.name =~ /org.freedesktop.DBus.Error.([A-Za-z.]*)/
      case $1
      when "ServiceUnknown"
        return ServiceNotAvailable.new('PackageKit')
      # bnc#559473
      when "Spawn.ChildExited"
        locked = nil
        begin
          pid = File.read("/var/run/zypp.pid").to_i
          locked = PackageKitError.new "The ZYpp package manager is locked by process #{pid}. Retry later."
        rescue Exception => e
          # it may have got unlocked already
          Rails.logger.error "OOPS #{e}"
        end
        return locked unless locked.nil?
      end
    end
    # otherwise unchanged
    dbus_error
  end

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

  # bnc#617350, remove signals
  def self.dbusloop_unregister(proxy)
    proxy.on_signal("Finished")
    proxy.on_signal("RepoSignatureRequired")
    proxy.on_signal("ErrorCode")
    proxy.on_signal("RepoDetail")
  end

  public

  #
  # PackageKit.lock
  #
  # Lock PackagKit for single use
  #
  def self.lock
    Rails.logger.info "PackageKit locking via DBUS lock"
    YastService.lock # Only one thread have access to DBUS. 
                     # So we have to synchronize with YastService calls
                     # Otherwise DBUS hangs
    Rails.logger.info "PackageKit locked"
  end

  #
  # PackageKit.unlock
  #
  # Unlock PackagKit
  #
  def self.unlock
    YastService.unlock
    Rails.logger.info "PackageKit unlocked via DBUS unlock"
  end

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
    system_bus = DBus::SystemBus.instance # RORSCAN_ITL
    # connect to PackageKit service via SystemBus
    pk_service = system_bus.service("org.freedesktop.PackageKit") # RORSCAN_ITL
    
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
  rescue DBus::Error => dbus_error
    raise self.improve_error dbus_error
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
      error = ''
      result = nil
      transaction_iface, packagekit_iface = self.connect
    
      proxy = transaction_iface.object
    
      # set the custom signal handler if set
      proxy.on_signal(signal.to_s, &block) if !signal.blank? && block_given?
      proxy.on_signal("Error") { dbusloop.quit }
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

      # bnc#617350, remove signals
      self.dbusloop_unregister proxy
      if bg_stat
        proxy.on_signal("ProgressChanged")
        proxy.on_signal("StatusChanged")
      end
      proxy.on_signal(signal.to_s) if !signal.blank? && block_given?
      proxy.on_signal("Error")

      raise PackageKitError.new(error) unless error.blank?

    rescue DBus::Error => dbus_error
      raise self.improve_error dbus_error
    rescue Exception => e
      raise e
    end
    
    result
  end


end
