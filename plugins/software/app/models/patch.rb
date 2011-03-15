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

require 'resolvable'

# Model for patches available via package kit
class Patch < Resolvable

  attr_accessor :messages

  MESSAGES_FILE = File.join(Paths::VAR,"software","patch_installion_messages")
  JOB_PRIO = -30

  private

  # create unique id for the background manager
  def self.job_id(what)
    "patch:install:#{what.inspect}"
  end

  public

  def to_xml( options = {} )
    super :patch_update, options, @messages
  end

  # install
  def install(background = false)
    # background process doesn't work correctly if class reloading is active
    # (static class members are lost between requests)
    # So the job queue is also not active
    if background && !YastCache.job_queue_enabled?
      Rails.logger.info "Job queue is not active. Disable background mode"
      background = false
    end
    update_id = "#{self.name};#{self.resolvable_id};#{self.arch};#{self.repo}"
    Rails.logger.error "Install Update: #{update_id}"
    unless background
      Patch.install(update_id) #install at once
    else
      #inserting job in background
      key = Patch.job_id(update_id)
      Rails.logger.info("Inserting job #{key}")
      Delayed::Job.enqueue(PluginJob.new(key),JOB_PRIO)
    end
  end

  # find patches using PackageKit
  def self.do_find(what)
    bg_status = nil #not needed due caching
    patch_updates = Array.new
    PackageKit.lock #locking
    begin
      PackageKit.transact("GetUpdates", "none", "Package", bg_status) { |line1,line2,line3|
        columns = line2.split ";"
        if what == :available || columns[1] == what
          update = Patch.new(:resolvable_id => columns[1],
                             :kind => line1,
                             :name => columns[0],
                             :arch => columns[2],
                             :repo => columns[3],
                             :summary => line3 )

          if what == :available
            # add the update to the list
            patch_updates << update
          else
            # just return this single update
            patch_updates = update
          end
        end
      }
    ensure
      #unlocking PackageKit
      PackageKit.unlock
    end
    return patch_updates
  end


  # find patches
  # Patch.find(:available)
  # Patch.find(212)
  def self.find(what, opts = {})
    search_id = what == :all ? :available : what
    YastCache.fetch("patch:find:#{what.inspect}") {
      do_find(search_id)
    }
  end

  # install an update, based on the PackageKit
  # id ("<name>;<id>;<arch>;<repo>")
  #
  def self.install(pk_id)
    Rails.logger.debug "Installing #{pk_id}"
    @messages=[]
    ret = do_install(pk_id,['RequireRestart','Message']) { |type, details|
      Rails.logger.info "Message signal received: #{type}, #{details}"
      @messages << {:kind => type, :details => details}
      begin
        dirname = File.dirname(MESSAGES_FILE)
        FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
        f = File.new(MESSAGES_FILE, 'a+')
        f.puts '<br/>' unless File.size(MESSAGES_FILE).zero?
        # TODO: make the message traslatable
        f.puts "#{details}"
      rescue Exception => e
        Rails.logger.error "writing #{MESSAGES_FILE} file failed: #{e.try(:message)}"
      ensure
        f.try(:close)
      end
    }
    #save installed patches in cache
    installed = Rails.cache.fetch("patch:installed") || []
    installed << pk_id
    Rails.cache.write("patch:installed", installed)
    
    YastCache.delete("patch:find:#{pk_id.split(';')[1].inspect}")
    return ret
  end

  def self.do_install(pk_id, signal_list = [], &block)
    #locking PackageKit for single use
    PackageKit.lock

    ok = true
    begin
      transaction_iface, packagekit_iface = PackageKit.connect

      proxy = transaction_iface.object
    
      if block_given?
        signal_list.each { |signal|
          # set the custom signal handle
          proxy.on_signal(signal.to_s, &block) 
        }
      end

      proxy.on_signal("Package") do |line1,line2,line3|
        Rails.logger.debug "  update package: #{line2}"
      end

      error = ''
      dbusloop = PackageKit.dbusloop proxy, error
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

      ok &= error.blank?

      # bnc#617350, remove signals
      proxy.on_signal "Error"
      proxy.on_signal "Package"
      if block_given?
        signal_list.each { |signal|
          proxy.on_signal signal.to_s
        }
      end
    ensure
      #unlocking PackageKit
      PackageKit.unlock
    end

    return ok
  end


end
