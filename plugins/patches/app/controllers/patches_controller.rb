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

#--------------------------------------------------------------------------------
#
#local methods
#
#--------------------------------------------------------------------------------

  def get_updateList
    patch_updates = [] 
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
      columns = line2.split ";"
      update = Patch.new( columns[1], 
                          line1, 
                          columns[0],
                          columns[2], 
                          columns[3], 
                          line3)
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
    patch_update = nil
    if @patch_updates.nil? || @patch_updates.empty?
      @patch_updates = get_updateList
    end
    @patch_updates.each do |p|   
       if p.resolvable_id.to_s == id.to_s
         patch_update = p
         break
       end
    end
    return patch_update
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
    unless permission_check( "org.opensuse.yast.system.patches.read")
      render ErrorResult.error(403, 1, "no permission") and return
    end
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
