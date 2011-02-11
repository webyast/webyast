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

  private

  # just a short cut for accessing the singleton object
  def self.bm
    BackgroundManager.instance
  end

  # create unique id for the background manager
  def self.id(what)
    "patches_#{what}"
  end

  public

  def to_xml( options = {} )
    super :patch_update, options, @messages
  end

  # install
  def install(background=false)
    @messages=[]
    update_id = "#{self.name};#{self.resolvable_id};#{self.arch};#{self.repo}"
    Rails.logger.error "Install Update: #{update_id}"
    Patch.install(update_id, background, ['RequireRestart','Message']) { |type, details|
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
  end

  # find patches using PackageKit
  def self.do_find(what, bg_status = nil)
    patch_updates = Array.new
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
    return patch_updates
  end

  def self.subprocess_find(what)
    # open subprocess
    subproc = open_subprocess :find, what

    result = nil

    while !eof_subprocess?(subproc) do
      begin
        line = read_subprocess subproc

        unless line.blank?
          received = Hash.from_xml(line)

          # is it a progress or the final list?
          if received.has_key? 'patches'
            Rails.logger.debug "Found #{received['patches'].size} patches"
            # create Patch objects
            result = received['patches'].map{|patch| Patch.new(patch.symbolize_keys) }
          elsif received.has_key? 'background_status'
            s = received['background_status']

            bm.update_progress id(what) do |bs|
              bs.status = s['status']
              bs.progress = s['progress']
              bs.subprogress = s['subprogress']
            end
          elsif received.has_key? 'error'
            return PackageKitError.new(received['error']['description'])
          else
            Rails.logger.warn "*** Patch thread: Received unknown input: #{line}"
          end
        end
      rescue Exception => e
        Rails.logger.error "Background thread: Could not evaluate output: #{line.chomp}, exception: #{e}" # RORSCAN_ITL
        Rails.logger.error "Background thread: Backtrace: #{e.backtrace.join("\n")}"

        # rethrow the exception
        raise e
      end
    end

    result
  end


  # find patches
  # Patch.find(:available)
  # Patch.find(:available, :background => true) - read patches in background
  #   the result may the current state (progress) or the actual patch list
  #   call this function in a loop until a patch list (or an error) is received
  # Patch.find(212)
  def self.find(what, opts = {})
    background = opts[:background]
    what = :available if what == :all #default search for cache

    return YastCache.fetch("patch:find:#{what.inspect}") if Rails.cache.exist?("patch:find:#{what.inspect}")

    # background reading doesn't work correctly if class reloading is active
    # (static class members are lost between requests)
    if background && !bm.background_enabled?
      Rails.logger.info "Class reloading is active, cannot use background thread (set config.cache_classes = true)"
      background = false
    end

    if background
      proc_id = id(what)
      if bm.process_finished? proc_id
        Rails.logger.debug "Request #{proc_id} is done"
        ret = bm.get_value proc_id

        # check for exception
        if ret.is_a? StandardError
          raise ret
        end

        Rails.cache.write("patch:find:#{what.inspect}", ret)

        return ret
      end

      running = bm.get_progress proc_id
      if running
        Rails.logger.debug "Request #{proc_id} is already running: #{running.inspect}"
        return [running]
      end


      bm.add_process proc_id

      Rails.logger.info "Starting background thread for reading patches..."
      # run the patch query in a separate thread
      Thread.new do
        res = subprocess_find what

        # check for exception
        unless res.is_a? StandardError
          Rails.logger.info "*** Patches thread: Found #{res.size} applicable patches"
        else
          Rails.logger.debug "*** Exception raised: #{res.inspect}"
        end
        bm.finish_process(proc_id, res)
      end

      return [ bm.get_progress(proc_id) ]
    else
      ret = do_find(what)
      Rails.cache.write("patch:find:#{what.inspect}", ret)
      return ret
    end
  end

  # install an update, based on the PackageKit
  # id ("<name>;<id>;<arch>;<repo>")
  # signal: signal to intercept (usually "Package") (optional)
  # block: block to run on signal (optional)
  #
  def self.install(pk_id, background = false, signal_list = nil, &block)
		Rails.logger.debug "Installing #{pk_id}, background: #{background.inspect}"

    # background process doesn't work correctly if class reloading is active
    # (static class members are lost between requests)
		bm = BackgroundManager.instance
    if background && !bm.background_enabled?
      Rails.logger.info "Class reloading is active, cannot use background thread (set config.cache_classes = true)"
      background = false
    end
    Rails.logger.debug "Background: #{background.inspect}"

    if background
      proc_id = bgid(pk_id)

      running = bm.get_progress proc_id
      if running
        Rails.logger.debug "Request #{proc_id} is already running: #{running.inspect}"
        return running
      end

      bm.add_process proc_id

      Rails.logger.info "Starting background thread for installing patches..."
      # run the patch query in a separate thread
      Thread.new do
				@@package_kit_mutex ||= Mutex.new #TODO move to packagekit lib
        @@package_kit_mutex.synchronize do
          res = subprocess_install pk_id

          # check for exception
          unless res.is_a? StandardError
            Rails.logger.info "*** Patch install thread: Result: #{res.inspect}"
          else
            Rails.logger.debug "*** Patch install thread: Exception raised: #{res.inspect}"
          end
          YastCache.reset("patch:find")
          bm.finish_process(proc_id, res)
        end
      end

      return bm.get_progress(proc_id)
    else
      ret = do_install(pk_id,signal_list,&block)
      YastCache.reset("patch:find")
      return ret
    end
  end

  def self.do_install(pk_id, signal_list = [], &block)
    ok = true
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
    packagekit_iface.SuggestDaemonQuit

    ok &= error.blank?

    # bnc#617350, remove signals
    proxy.on_signal "Error"
    proxy.on_signal "Package"
    if block_given?
      signal_list.each { |signal|
        proxy.on_signal signal.to_s
      }
    end

    return ok
  end

private

  def self.bgid(what)
    "packagekit_install_#{what}"
  end

  def self.subprocess_script(type)
		file = case type
			when :find then  "list_patches.rb"
			when :install then "install_patches.rb"
			else raise "unsupported type"
			end
    # find the helper script
    script = File.join(RAILS_ROOT, 'vendor/plugins/software/scripts',file) # RORSCAN_ITL

    unless File.exists? script # RORSCAN_ITL
      script = File.join(RAILS_ROOT, '../plugins/software/scripts',file) # RORSCAN_ITL

      unless File.exists? script # RORSCAN_ITL
        raise "File software/scripts/#{file} was not found!" # RORSCAN_ITL
      end
    end

    Rails.logger.debug "Using #{script} script file" # RORSCAN_ITL
    script
  end

  def self.subprocess_command(type,what)
    raise "Invalid parameter" if what.to_s.include?("'") or what.to_s.include?('\\')
    ret = "cd #{RAILS_ROOT} && RAILS_ENV=#{ENV['RAILS_ENV'] || 'development'} #{File.join(RAILS_ROOT, 'script/runner')} #{subprocess_script type} "
    ret = ret + "'#{what}'" if type == :install #only install use specified patches
    return ret
  end

  # IO functions moved to separate methods for easy mocking/testing

  def self.open_subprocess(type,what)
    IO.popen subprocess_command(type,what)
  end

  def self.read_subprocess(subproc)
    subproc.readline
  end

  def self.eof_subprocess?(subproc)
    subproc.eof?
  end

    def self.subprocess_install(what)
    # open subprocess
    subproc = open_subprocess :install, what

    result = nil

    while !eof_subprocess?(subproc) do
      begin
        line = read_subprocess subproc

        unless line.blank?
          received = Hash.from_xml(line)

          # is it a progress or the final list?
          if received.has_key? 'patch_installation'
            Rails.logger.debug "Received background patch installation result: #{received['patch_installation'].inspect}"
            # create Patch objects
            result = received['patch_installation']['result']
          elsif received.has_key? 'background_status'
            s = received['background_status']

            bm.update_progress bgid(what) do |bs|
              bs.status = s['status']
              bs.progress = s['progress']
              bs.subprogress = s['subprogress']
            end
          elsif received.has_key? 'error'
            return PackageKitError.new(received['error']['description'])
          else
            Rails.logger.warn "*** Patch installtion thread: Received unknown input: #{line}"
          end
        end
      rescue Exception => e
        Rails.logger.error "Background thread: Could not evaluate output: #{line.chomp}, exception: #{e}" # RORSCAN_ITL
        Rails.logger.error "Background thread: Backtrace: #{e.backtrace.join("\n")}"

        # rethrow the exception
        raise e
      end
    end

    result
  end
end
