include ApplicationHelper

class NetworksController < ApplicationController

  before_filter :login_required

#  def show
#    unless permission_check("org.opensuse.yast.system.network.read")
#      render ErrorResult.error(403, 1, "no permission") and return
#    else
#      @network = Network.new
#    end
#  end

  def index
      # read all network settings
      if !permission_check("org.opensuse.yast.system.network.read")
          render ErrorResult.error(403, 1, "no permission") and return
      end

      @networks = Network.find_all

      respond_to do |format|
          format.html { render :xml => @networks, :location => "none" } #return xml only
          format.xml  { render :xml => @networks, :location => "none" }
          format.json { render :json => @networks.to_json, :location => "none" }
      end
  end

  def get_device (id)
    ret = Scr.instance.execute(["/sbin/yast2", "lan", "show", "id=#{id}"])
    if (!ret or
        ret[:stderr].include?("There is no such device."))
      return false
    end
    lines = ret[:stderr].split "\n"
    counter = 0
    @network = Network.new
    @network.id = id

    @network.description = ""
    @network.mac = ""
    @network.dev_name = ""
    @network.startup = ""

    begin
     @network.description = lines[0].strip
    rescue
    end

    begin
     @network.mac = (lines[1].split ": ")[1].strip
    rescue
    end

    begin
     @network.dev_name = (lines[2].split ": ")[1].strip
    rescue
    end

    begin
     @network.startup = lines[3].strip
    rescue
    end
    
    return true
  end


  # GET /users/1
  # GET /users/1.xml
  def show
    unless permission_check( "org.opensuse.yast.system.network.read")
      render ErrorResult.error(403, 1, "no permission") and return
    end
    if params[:id].blank?
      render ErrorResult.error(404, 2, "empty parameter") and return
    end
    unless get_device params[:id]
      render ErrorResult.error(404, 2, "user not found") and return
    end
  end


end


