
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
    finished = false
    while !finished do
      ready, dum, dum = IO.select(@buses.keys)
      ready.each do |socket|
        b = @buses[socket]
        b.update_buffer
        while m = b.pop_message
          b.process(m)
	  if m.member = "Finished" || m.member = "Error"
            finished = true
          end
        end
      end
    end
  end
end # class MainPkg


class PatchUpdatesController < ApplicationController

   before_filter :login_required

#--------------------------------------------------------------------------------
#
#local methods
#
#--------------------------------------------------------------------------------

  def get_updateList
    system_bus = DBus::SystemBus.instance
    packageKit = system_bus.service("org.freedesktop.PackageKit")
    obj = packageKit.object("/org/freedesktop/PackageKit")
    obj.introspect
    obj_with_iface = obj["org.freedesktop.PackageKit"]
    tid = obj_with_iface.GetTid
    objTid = packageKit.object(tid[0])
    objTid.introspect
    objTid_with_iface = objTid["org.freedesktop.PackageKit.Transaction"]
    objTid.default_iface = "org.freedesktop.PackageKit.Transaction"

    @finished = false
    @patch_updates = [] 
    objTid.on_signal("Package") do |line1,line2,line3|
      update = PatchUpdate.new
      update.kind = line1
      update.summary = line3
      columns = line2.split ";"
      update.name = columns[0]
      update.resolvableId = columns[1]
      update.arch = columns[2]
      update.repo = columns[3]
      @patch_updates << update
    end

    objTid.on_signal("Error") do |u1,u2|
      @finished = true
    end
    objTid.on_signal("Finished") do |u1,u2|
      @finished = true
    end
    objTid_with_iface.GetUpdates("NONE")

    if !@finished
      @main = MainPkg.new
      @main << system_bus
      @main.run
    end

    obj_with_iface.SuggestDaemonQuit
  end

  def get_update (id)
    if @patch_updates == nil || @patch_updates.length == 0
      get_updateList
    end
    @patch_updates::each do |p|   
       if p.resolvableId = id
         @patch_update = p
         break
       end
    end
  end

  def install_update (id)
    get_update (id)
    if @patch_update == nil
      logger.error "Patch: #{id} not found."
      return
    end

    updateId = "#{@patch_update.name};#{@patch_update.resolvableId};#{@patch_update.arch};#{@patch_update.repo}"
    logger.debug "Install Update: #{updateId}"
   
    system_bus = DBus::SystemBus.instance
    packageKit = system_bus.service("org.freedesktop.PackageKit")
    obj = packageKit.object("/org/freedesktop/PackageKit")
    obj.introspect
    obj_with_iface = obj["org.freedesktop.PackageKit"]
    tid = obj_with_iface.GetTid
    objTid = packageKit.object(tid[0])
    objTid.introspect
    objTid_with_iface = objTid["org.freedesktop.PackageKit.Transaction"]
    objTid.default_iface = "org.freedesktop.PackageKit.Transaction"

    @finished = false
    objTid.on_signal("Package") do |line1,line2,line3|
      logger.debug "  update package: #{line2}"
    end

    objTid.on_signal("Error") do |u1,u2|
      @finished = true
    end
    objTid.on_signal("Finished") do |u1,u2|
      @finished = true
    end
    objTid_with_iface.InstallPackages([updateId])

    if !@finished
      @main = MainPkg.new
      @main << system_bus
      @main.run
    end

    obj_with_iface.SuggestDaemonQuit
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
      format.html # index.html.erb
      format.xml  { render :xml => @patch_updates }
      format.json { render :json => @patch_updates.to_json }
    end
  end

  # GET /patch_updates/1
  # GET /patch_updates/1.xml
  def show
    get_update params[:id]

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @patch_update }
      format.json { render :json => @patch_update.to_json }
    end
  end

  # POST /patch_updates/1
  # POST /patch_updates/1.xml
  def install
    install_update params[:id]

    respond_to do |format|
      format.html { redirect_to(patch_updates_url) }
      format.xml  { head :ok }
    end
  end

end
