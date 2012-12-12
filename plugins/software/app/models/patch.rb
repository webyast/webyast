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

require 'yast/paths'

# FIXME: clear the mess (Patch.install vs. Patch#install)

# Model for patches available via package kit
class Patch < Resolvable
  BM = BackgroundManager.instance

  attr_accessor :messages
  attr_accessor :error_message

  MESSAGES_FILE = File.join(YaST::Paths::VAR,"software","patch_installion_messages")
  LICENSES_DIR = File.join(YaST::Paths::VAR,"software","licenses")
  ACCEPTED_LICENSES_DIR = File.join(YaST::Paths::VAR,"software","licenses","accepted")
  JOB_PRIO = -30
  EXPIRATION_TIME = 10.minutes

  PATCH_INSTALL_ID = "patch_install"
  PATCH_FIND_ID = "patch_find_"
  PATCH_FIND_MTIME = "patch_find_mtime_"

  private

  def self.decide_license(accept)
    #we don't know eula id, but as it block package kit, then there is only one license file to decide
    if accept
      `/usr/bin/find #{LICENSES_DIR} -type f -exec /bin/mv {} #{ACCEPTED_LICENSES_DIR} \\;`
    else
      `/usr/bin/find #{LICENSES_DIR} -type f -delete`
    end
  end

  def self.install_patches(patches)
    patches.each do |patch|
      patch.install
    end
  end

  public

  def self.accept_license
    decide_license true
  end

  def self.reject_license
    decide_license false
  end

  def to_xml( options = {} )
    super :patch_update, options, @messages
  end

  def self.mtime
    [PackageKit.mtime, Repository.mtime].max
  end

  def self.install_patches_by_id_background ids
    if Patch::BM.add_process(Patch::PATCH_INSTALL_ID)
      Rails.logger.info "Installing #{ids.size} patches in background"

      Thread.new do
        install_patches_by_id ids
      end
    end
  end

  def self.clear_cache
    Rails.logger.info "** Clearing patch cache"

    Rails.cache.delete_matched /#{PATCH_FIND_ID}_/
    Rails.cache.delete_matched /#{PATCH_FIND_MTIME}_/
    Rails.cache.delete_matched /webyast_patch_summary_/
    Rails.cache.delete_matched /webyast_patch_index_/
  end

  def self.install_patches_by_id ids
    begin
      patches = []

      ids.each do |id|
        patch = Patch.find(id)
        patches << patch if patch
      end

      Rails.logger.info "** Found #{patches.size} patches to install"

      # set number of patches to install
      Patch::BM.update_progress(Patch::PATCH_INSTALL_ID) do |bs|
        bs.status = "0/#{patches.size}"
      end

      patches.each_with_index do |patch, idx|
        Rails.logger.info "** Installing patch #{patch.inspect}"

        patch.do_install

        Patch::BM.update_progress(Patch::PATCH_INSTALL_ID) do |bs|
          bs.status = "#{idx + 1}/#{patches.size}"
        end
      end

      Rails.logger.info "** Patch installation finished"

      Patch::BM.finish_process(Patch::PATCH_INSTALL_ID, patches)
    rescue Exception => e
      Patch::BM.finish_process(Patch::PATCH_INSTALL_ID, e)
    ensure
      self.clear_cache
    end
  end

  def do_install
    update_id = self.resolvable_id

    Rails.logger.info("Installing update #{update_id}")
    ret, error = Patch.install(update_id)

    if error.blank?
      #save installed patches in cache
      Rails.logger.info "Updating installed cache"
      i = Rails.cache.fetch("patch:installed") || []
      installed = i.dup #cache is frozen
      self.installed = true
      installed << self
      Rails.logger.debug "Cached installed patches: #{installed.inspect}"
      Rails.cache.write("patch:installed", installed)
    else
      Rails.logger.info "Updating failed cache..."
      f = Rails.cache.fetch("patch:failed") || []
      failed = f.dup
      self.error_message = error
      failed << self
      Rails.logger.debug "Cached failed patches: #{failed.inspect}"
      Rails.cache.write("patch:failed", failed)
    end
  end

  # install
  def install(background = false)
    # background process doesn't work correctly if class reloading is active
    # (static class members are lost between requests)
    # So the job queue is also not active
    if background && !BM.background_enabled?
      Rails.logger.info "Job queue is not active. Disabling background mode"
      background = false
    end

    update_id = self.resolvable_id

    if background
      Thread.new() do
        Rails.logger.info("Installing update #{update_id} in a backround thread")
        Patch.install(update_id)
      end
    else
      Rails.logger.info("Installing update #{update_id}")
      Patch.install(update_id) #install at once
    end
  end

  # find patches using PackageKit
  def self.do_find(what)
    bg_status = nil #not needed due caching
    patch_updates = Array.new

    DbusLock.synchronize do
      PackageKit.transact("GetUpdates", "none", "Package", bg_status) do |line1,line2,line3|
        columns = line2.split ";"
        if what == :available || line2 == what
          update = Patch.new(:resolvable_id => line2,
            :version => columns[1],
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
      end
    end

    patch_updates
  end

  def self.install_all_background
    if Patch::BM.add_process(Patch::PATCH_INSTALL_ID)
      Rails.logger.info "Installing all available patches in background"

      Thread.new do
        install_all
      end
    end
  end

  def self.install_all
    begin
      patches = Patch.do_find(:available)

      # set number of patches to install
      Patch::BM.update_progress(Patch::PATCH_INSTALL_ID) do |bs|
        bs.status = "0/#{patches.size}"
      end

      patches.each_with_index do |patch, idx|
        patch.do_install

        Patch::BM.update_progress(Patch::PATCH_INSTALL_ID) do |bs|
          bs.status = "#{idx + 1}/#{patches.size}"
        end
      end

      Patch::BM.finish_process(Patch::PATCH_INSTALL_ID, patches)
    rescue Exception => e
      Patch::BM.finish_process(Patch::PATCH_INSTALL_ID, e)
    end
  end

  def self.installing
    progress = Patch::BM.get_progress(Patch::PATCH_INSTALL_ID)

    return [false, 0] unless progress

    remaining = nil
    if progress.status.match /^([0-9]+)\/([0-9]+)/
      remaining = $2.to_i - $1.to_i
    end

    return [true, remaining]
  end


  # find patches
  # Patch.find(:available)
  # Patch.find(212)
  def self.find(what, opts = {})
    search_id = what == :all ? :available : what

    find_id = "#{PATCH_FIND_ID}_#{search_id}"
    mtime_id = "#{PATCH_FIND_MTIME}_#{search_id}"
    patch_mtime = Patch.mtime

    # check the cache
    if patch_mtime != Rails.cache.fetch(mtime_id)
      Rails.logger.debug "Invalidating patch cache '#{mtime_id}'" unless Rails.cache.fetch(mtime_id).nil?
      Rails.cache.delete(find_id)
    end

    Rails.cache.fetch(find_id, :expires_in => Patch::EXPIRATION_TIME) do
      # update time stamp
      Rails.cache.write(mtime_id, patch_mtime)
      do_find(search_id)
    end
  end

  # install an update, based on the PackageKit
  # id ("<name>;<id>;<arch>;<repo>")
  #
  def self.install(pk_id)
    Rails.logger.debug "Installing #{pk_id}"
    @messages=[]
    ret, error = do_install(pk_id,['RequireRestart','Message']) { |type, details|
      Rails.logger.info "Message signal received: #{type}, #{details}"
      @messages << {:kind => type, :details => details}
      begin
        dirname = File.dirname(MESSAGES_FILE)
        FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
        f = File.new(MESSAGES_FILE, 'a+')
        # TODO: make the messages traslatable
        name, id, arch, repo = pk_id.split(';')
        f.puts "Patch #{name} from #{repo}: #{details}\n"
      rescue Exception => e
        Rails.logger.error "writing #{MESSAGES_FILE} file failed: #{e.try(:message)}"
      ensure
        f.try(:close)
      end
    }

    return ret, error
  end

  def self.license
    Dir.glob(File.join(LICENSES_DIR,"*")).reduce([]) do |res,f|
      if File.file? f
        res << ({
            :name => File.basename(f),
            :text => File.read(f)
          })
      end
      res
    end
  end


  def self.do_install(pk_id, signal_list = [], &block)
    #locking PackageKit for single use
    ok = true
    error = ''

    DbusLock.synchronize do
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

        dbusloop = PackageKit.dbusloop proxy, error
        dbusloop << proxy.bus
        accept_eulas()

        proxy.on_signal("Error") do |u1,u2|
          ok = false
          dbusloop.quit
        end

        proxy.on_signal("EulaRequired") do |eula_id,package_id,vendor_name,license_text|
          Rails.logger.info "EULA #{eula_id.inspect} is required for #{package_id.inspect}"
          #FIXME check if user already agree with license
          create_eula(eula_id,license_text)
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
        proxy.on_signal "EulaRequired"
        if block_given?
          signal_list.each { |signal|
            proxy.on_signal signal.to_s
          }
        end
      end
    end

    Rails.logger.error "Received PackageKit error: #{error}" unless error.blank?

    remove_eulas() if ok
    return [ ok, error ]
  end

  def self.create_eula(eula_id,license_text)
    accepted_path = File.join(ACCEPTED_LICENSES_DIR,eula_id)
    ret = File.exists?(accepted_path) #eula is in accepted dir
    unless ret
      license_file = File.join(LICENSES_DIR,eula_id)
      File.open(license_file,"w") { |f| f.write license_text }
    end
    ret
  end

  def self.accept_eulas()
    dir = Dir.new(ACCEPTED_LICENSES_DIR)
    dir.each  {|filename|
      unless File.directory? filename
        eula_id = File.basename filename
        Rails.logger.info "accepting #{eula_id.inspect} ."
        begin
          PackageKit.transact :AcceptEula, [eula_id],nil,nil
        rescue Exception => e
          Rails.logger.info "accepting eula #{eula_id} failed: #{e.inspect}"
        end
      end
    }
  end

  def self.remove_eulas()
    dir = Dir.new(ACCEPTED_LICENSES_DIR)
    dir.each  {|filename|
      File.delete(File.join(ACCEPTED_LICENSES_DIR,filename)) unless File.directory? filename
    }
  end

end
