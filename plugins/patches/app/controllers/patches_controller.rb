require "dbus"
require 'socket'
require 'thread'
require 'singleton'


# = MainPkg event loop class.
#
# Class that takes care of handling message and signal events
# asynchronously.
class MainPkg
  # Create a new main event loop.
  def initialize
    @buses = Hash.new
  end

  # Add a _bus_ to the list of buses to watch for events.
  def <<(bus)
    @buses[bus.socket] = bus
  end

  # Run the main loop. This is a blocking call!
  def run
    ok = true
    finished = false
    while !finished do
      ready, dum, dum = IO.select(@buses.keys)
      ready.each do |socket|
        b = @buses[socket]
        b.update_buffer
        while m = b.pop_message
          b.process(m)
	  if m.member == "Finished" || m.member == "Errorcode"
            finished = true
            if m.member == "Error"
               ok = false
            end
          end
        end
      end
    end
    return ok
  end
end # class MainPkg


class PatchesController < ApplicationController

   before_filter :login_required
   
   # always check permissions and cache expiration
   # even if the result is already created and cached
   before_filter :check_read_permissions, :only => :index
   before_filter :check_cache_status, :only => :index

   # cache 'index' method result
   caches_action :index

#--------------------------------------------------------------------------------
#
#local methods
#
#--------------------------------------------------------------------------------

  private

  def check_read_permissions
    unless permission_check( "org.opensuse.yast.system.patches.read")
      render ErrorResult.error(403, 1, "no permission") and return
    end
  end

  # check whether the cached result is still valid
  def check_cache_status
    cache_timestamp = Rails.cache.read('patches:timestamp')

    if cache_timestamp.nil?
	# this is the first run, the cache is not initialized yet, just return
	Rails.cache.write('patches:timestamp', Time.now)
	return
    # the cache expires after 5 minutes, repository metadata
    # or RPM database update invalidates the cache immeditely
    # (new patches might be applicable)
    elsif cache_timestamp < 5.minutes.ago ||
    cache_timestamp < File.stat("/var/lib/rpm/Packages").mtime ||
    cache_timestamp < File.stat("/var/cache/zypp/solv").mtime ||
    Dir["/var/cache/zypp/solv/*/solv"].find{ |x| File.stat(x).mtime > cache_timestamp}
	logger.debug "#### Patch cache expired"
	expire_action :action => :index, :format => params["format"]
	Rails.cache.write('patches:timestamp', Time.now)
    end
  end

  public

  def get_updateList
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

    finished = false
    obj_tid.on_signal("Package") do |line1,line2,line3|
      columns = line2.split ";"
      update = Patch.new(columns[1], line1, columns[0], columns[2], columns[3], line3)
      patch_updates << update
      finished = true
    end

    obj_tid.on_signal("Error") do |u1,u2|
      finished = true
    end
    obj_tid.on_signal("Finished") do |u1,u2|
      finished = true
    end
    obj_tid_with_iface.GetUpdates("NONE")

    unless finished
      @main = MainPkg.new
      @main << system_bus
      @main.run
    end

    obj_with_iface.SuggestDaemonQuit

    return patch_updates
  end

  def get_update (id)
    if @patch_updates.nil? || @patch_updates.empty?
      @patch_updates = get_updateList
    end

    @patch_updates.find { |p| p.resolvable_id.to_s == id.to_s }
  end

  def install_update (id)
    ok = true

    updateId = "#{@patch_update.name};#{@patch_update.resolvable_id};#{@patch_update.arch};#{@patch_update.repo}"
    logger.debug "Install Update: #{updateId}"

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
      logger.debug "  update package: #{line2}"
    end

    obj_tid.on_signal("Error") do |u1,u2|
      finished = true
      ok = false
    end
    obj_tid.on_signal("Finished") do |u1,u2|
      finished = true
    end
    obj_tid_with_iface.UpdatePackages([updateId])

    unless finished
      @main = MainPkg.new
      @main << system_bus
      if (!@main.run)
         ok = false
      end
    end
    obj_with_iface.SuggestDaemonQuit

    return ok
  end


#--------------------------------------------------------------------------------
#
# actions
#
#--------------------------------------------------------------------------------



  # GET /patch_updates
  # GET /patch_updates.xml
  def index
    # note: permission check was performed in :before_filter

    @patch_updates = get_updateList
  end

  # GET /patch_updates/1
  # GET /patch_updates/1.xml
  def show
    unless permission_check( "org.opensuse.yast.system.patches.read")
      render ErrorResult.error(403, 1, "no permission") and return
    end
    @patch_update = get_update params[:id]
    if @patch_update.nil?
      logger.error "Patch: #{params[:id]} not found."
      render ErrorResult.error(404, 1, "Patch: #{params[:id]} not found.") and return
    end
  end

  # PUT /patch_updates/1
  # PUT /patch_updates/1.xml
  def update
    unless permission_check( "org.opensuse.yast.system.patches.install")
      render ErrorResult.error(403, 1, "no permission") and return
    end
    @patch_update = get_update(params[:id])
    if @patch_update.nil?
      logger.error "Patch: #{params[:id]} not found."
      render ErrorResult.error(404, 1, "Patch: #{params[:id]} not found.") and return
    end
    unless install_update params[:id]
      render ErrorResult.error(404, 2, "packagekit error") and return
    end
    render :show
  end

end
