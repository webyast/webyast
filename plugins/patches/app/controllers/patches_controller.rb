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
    @patch_updates = [] 
    if permission_check( "org.opensuse.yast.system.patches.read")
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

       @finished = false
       obj_tid.on_signal("Package") do |line1,line2,line3|
         update = Patch.new
         update.kind = line1
         update.summary = line3
         columns = line2.split ";"
         update.name = columns[0]
         update.resolvable_id = columns[1]
         update.arch = columns[2]
         update.repo = columns[3]
         @patch_updates << update
         @finished = true
       end

       obj_tid.on_signal("Error") do |u1,u2|
         @finished = true
       end
       obj_tid.on_signal("Finished") do |u1,u2|
         @finished = true
       end
       obj_tid_with_iface.GetUpdates("NONE")

       if !@finished
         @main = MainPkg.new
         @main << system_bus
         @main.run
       end
 
       obj_with_iface.SuggestDaemonQuit
    else
       update = Patch.new
       update.error_id = 1
       update.error_string = "no permission"
       @patch_updates << update
    end
  end

  def get_update (id)
    @patch_update = nil
    if @patch_updates.nil? || @patch_updates.empty?
      get_updateList
    end
    @patch_updates.each do |p|   
       if p.resolvable_id.to_s == id.to_s
         @patch_update = p
         break
       end
    end
  end

  def install_update (id)
    ret = "ok"
    get_update (id)
    if @patch_update.nil?
      logger.error "Patch: #{id} not found."
      return "Patch: #{id} not found."
    end

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

    @finished = false
    obj_tid.on_signal("Package") do |line1,line2,line3|
      logger.debug "  update package: #{line2}"
    end

    obj_tid.on_signal("Error") do |u1,u2|
      @finished = true
      ret = "packageKit Error"
    end
    obj_tid.on_signal("Finished") do |u1,u2|
      @finished = true
    end
    obj_tid_with_iface.UpdatePackages([updateId])

    if !@finished
      @main = MainPkg.new
      @main << system_bus
      if (!@main.run)
         ret = "packageKit Error"
      end
    end
    obj_with_iface.SuggestDaemonQuit

    return ret
  end


#--------------------------------------------------------------------------------
#
# actions
#
#--------------------------------------------------------------------------------



  # GET /patch_updates
  # GET /patch_updates.xml
  def index
    get_updateList
    respond_to do |format|
      format.html { render :xml => @patch_updates } #return xml only
      format.xml  { render :xml => @patch_updates.to_xml(:dasherize => false) }
      format.json { render :json => @patch_updates.to_json }
    end
  end

  # GET /patch_updates/1
  # GET /patch_updates/1.xml
  def show
    get_update params[:id]
    respond_to do |format|
      format.html { render :xml => @patch_update } #return xml only
      format.xml  { render :xml => @patch_update }
      format.json { render :json => @patch_update.to_json }
    end
  end

  # POST /patch_updates/1
  # POST /patch_updates/1.xml
  def install
    update = Patch.new
    if permission_check( "org.opensuse.yast.system.patches.install")
       ret = install_update params[:id]
       if (ret != "ok")
          update.error_id = 1
          update.error_string = ret
       end
    else
       update.error_id = 1
       update.error_string = "no permission"
    end

    respond_to do |format|
      format.html { render :xml => update } #return xml only
      format.xml  { render :xml => update }
      format.json { render :json => update.to_json }
    end
  end

end
