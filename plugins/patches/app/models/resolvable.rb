#
# Model for resolvables available via package kit
#
require "dbus"
require 'socket'
require 'thread'

require 'exceptions'

class Resolvable

  attr_accessor   :resolvable_id,
                  :kind,
                  :name,
		  :version,
                  :arch,
                  :repo,
                  :summary,
                  :installing,
                  :installed

private

  # allow only one thread accessing PackageKit
  @@package_kit_mutex = Mutex.new

  #
  # Resolvable.packagekit_connect
  #
  # connect to PackageKit and create Transaction proxy
  #
  # return Array of <transaction proxy>,<packagekit interface>,<transaction 
  #
  # Reference: http://www.packagekit.org/gtk-doc/index.html
  #

  def self.packagekit_connect
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

    xml.tag! tag do
      xml.tag!(:resolvable_id, @resolvable_id, {:type => "integer"} )
      xml.tag!(:kind, @kind )
      xml.tag!(:name, @name )
      xml.tag!(:version, @version )
      xml.tag!(:arch, @arch )
      xml.tag!(:repo, @repo )
      xml.tag!(:summary, @summary )
      xml.tag!(:installing, @installing, {:type => "boolean"} )
      xml.tag!(:installed, @installed )
    end

  end
  
  def to_json( options = {} )
    hash = Hash.from_xml(self.to_xml())
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

  #
  # Execute PackageKit transaction method
  #
  # method: method to execute
  # args: arguments to method
  # signal: signal to intercept (usuallay "Package")
  # block: block to run on signal
  #
  def self.execute(method, args, signal, &block)
    begin
      dbusloop = DBus::Main.new
      transaction_iface, packagekit_iface = self.packagekit_connect
    
      proxy = transaction_iface.object
    
      proxy.on_signal(signal.to_s, &block)
      proxy.on_signal("ErrorCode") {|u1,u2| dbusloop.quit }
      proxy.on_signal("Finished") {|u1,u2| dbusloop.quit }
      # Do the call only when all signal handlers are in place,
      # otherwise Finished can arrive early and dbusloop will never
      # quit, bnc#561578
      transaction_iface.send(method.to_sym, *args)

      dbusloop << DBus::SystemBus.instance
      dbusloop.run

      # bnc#617350, remove signals
      proxy.on_signal(signal.to_s)
      proxy.on_signal("ErrorCode")
      proxy.on_signal("Finished")

      packagekit_iface.SuggestDaemonQuit
    rescue DBus::Error => dbus_error
      # check if it is a known error
      raise ServiceNotAvailable.new('PackageKit') if dbus_error.message =~ /org.freedesktop.DBus.Error.ServiceUnknown/
      # otherwise rethrow
      raise dbus_error
    rescue Exception => e
      raise e
    end
  end

  # create a unique ID for BackgroundManager
  def self.bgid(what)
    "packagekit_install_#{what}"
  end

  # install an update, based on the PackageKit
  # id ("<name>;<id>;<arch>;<repo>")
  #
  def self.package_kit_install(pk_id, background = false)
    Rails.logger.debug "Installing #{pk_id}, background: #{background.inspect}"

    # background process doesn't work correctly if class reloading is active
    # (static class members are lost between requests)
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
        @@package_kit_mutex.synchronize do
          res = subprocess_install pk_id

          # check for exception
          unless res.is_a? StandardError
            Rails.logger.info "*** Patch install thread: Result: #{res.inspect}"
          else
            Rails.logger.debug "*** Patch install thread: Exception raised: #{res.inspect}"
          end
          bm.finish_process(proc_id, res)
        end
      end

      return bm.get_progress(proc_id)
    else
      return do_package_kit_install(pk_id)
    end
  end

  def self.do_package_kit_install(pk_id, bs = nil)
    ok = true
    transaction_iface, packagekit_iface = self.packagekit_connect

    proxy = transaction_iface.object
    proxy.on_signal("Package") do |line1,line2,line3|
      Rails.logger.debug "  update package: #{line2}"
      if bs
        bs.status = "#{line1} #{line2}"
      end
    end

    $stderr.puts "do_package_kit_install: installing #{pk_id}"

    dbusloop = DBus::Main.new
    dbusloop << DBus::SystemBus.instance

    proxy.on_signal("Finished") {|u1,u2| dbusloop.quit }
    proxy.on_signal("ErrorCode") do |u1,u2|
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

    # bnc#617350, remove signals
    proxy.on_signal("Package")
    proxy.on_signal("ErrorCode")
    proxy.on_signal("Finished")
 
    packagekit_iface.SuggestDaemonQuit

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


  private

  def self.subprocess_script
    # find the helper script
    script = File.join(RAILS_ROOT, 'vendor/plugins/patches/scripts/install_patches.rb')

    unless File.exists? script
      script = File.join(RAILS_ROOT, '../plugins/patches/scripts/install_patches.rb')

      unless File.exists? script
        raise 'File patches/scripts/install_patches.rb was not found!'
      end
    end

    Rails.logger.debug "Using #{script} script file"
    script
  end

  def self.subprocess_command(what)
    raise "Invalid parameter" if what.to_s.include?("'") or what.to_s.include?('\\')
    "cd #{RAILS_ROOT} && #{File.join(RAILS_ROOT, 'script/runner')} -e #{ENV['RAILS_ENV'] || 'development'} #{subprocess_script} '#{what}'"
  end

  # IO functions moved to separate methods for easy mocking/testing

  def self.open_subprocess(what)
    IO.popen(subprocess_command what)
  end

  def self.read_subprocess(subproc)
    subproc.readline
  end

  def self.eof_subprocess?(subproc)
    subproc.eof?
  end


  def self.subprocess_install(what)
    # open subprocess
    subproc = open_subprocess what

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
        Rails.logger.error "Background thread: Could not evaluate output: #{line.chomp}, exception: #{e}"
        Rails.logger.error "Background thread: Backtrace: #{e.backtrace.join("\n")}"

        # rethrow the exception
        raise e
      end
    end

    result
  end

  # just a short cut for accessing the singleton object
  def self.bm
    BackgroundManager.instance
  end

end
