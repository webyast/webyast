require "scr"

# import YastService class FIXME move into the model...
require "yast_service"

include ApplicationHelper

class UsersController < ApplicationController
  
  before_filter :login_required

  def initialize
    @scr = Scr.instance
  end
  
#--------------------------------------------------------------------------------
#
#local methods
#
#--------------------------------------------------------------------------------


  def get_user_list
    @users = []
    parameters	= {
	# how to index hash with users
	"index"	=> [ "s", "uid" ],
	# attributes to return for each user
	"user_attributes"	=> [ "as", [ "cn" ]]
    }
    users_map = YastService.Call("YaPI::USERS::UsersGet", parameters)
    if users_map.nil?
	puts "something wrong happened -------------------------------------"
    else
	users_map.each do |key, val|
	    user = User.new
	    user.uid		= key
	    user.cn		= val["cn"]
	    @users << user
	end
    end
  end

  def get_user (id)
    if @user
      saveKey = @user.sshkey
    else
      saveKey = nil
    end
    parameters	= {
	# user to find
	"uid"	=> [ "s", id ],
	# list of attributes to return;
	"user_attributes"	=> [ "as", [
	    "cn", "uidNumber", "homeDirectory",
	    "grouplist", "uidloginShell", "groupname"
	]]
    }
    user_map = YastService.Call("YaPI::USERS::UserGet", parameters)
    # TODO check if it is not empty

    @user 	= User.new

#FIXME why User.new (user_map) does not work?

    @user.grouplist	= user_map["grouplist"]
    @user.homeDirectory	= user_map["homeDirectory"]
    @user.groupname	= user_map["groupname"]
    @user.loginShell	= user_map["loginShell"]
    @user.uid		= id
    @user.uidNumber	= user_map["uidNumber"]
    @user.cn		= user_map["cn"]

    @user.sshkey	= saveKey
    return true
  end

  def createSSH
    if @user.homeDirectory.blank?
      save_key = @user.sshkey
      get_user @user.uid
      @user.sshkey = save_key
    end
    ret = @scr.read(".target.stat", "#{@user.homeDirectory}/.ssh/authorized_keys")
    if ret.empty?
      logger.debug "Create: #{@user.homeDirectory}/.ssh/authorized_keys"
      @scr.execute(["/bin/mkdir", "#{@user.homeDirectory}/.ssh"])      
      @scr.execute(["/bin/chown", "#{@user.uid}", "#{@user.homeDirectory}/.ssh"])      
      @scr.execute(["/bin/chmod", "755", "#{@user.homeDirectory}/.ssh"])
      @scr.execute(["/usr/bin/touch", "#{@user.homeDirectory}/.ssh/authorized_keys"])      
      @scr.execute(["/bin/chown", "#{@user.uid}", "#{@user.homeDirectory}/.ssh/authorized_keys"])      
      @scr.execute(["/bin/chmod", "644", "#{@user.homeDirectory}/.ssh/authorized_keys"])
    end
    ret = @scr.execute(["echo", "\"#{@user.sshkey}\"", ">>", "#{@user.homeDirectory}/.ssh/authorized_keys"])
    @error_id = ret[:exit]
    if ret[:exit] != 0
      @error_string = ret[:stderr]
      return false
    else 
      @error_string = ""
      return true
    end
  end

  # -------------------------------------------------------
  # modify existing user
  def update_user userId
    ok = true

    if not @user.sshkey.blank?
      ok = createSSH
    end

    config	= {
	"type"	=> [ "s", "local" ],
	"uid"	=> [ "s", @user.uid ]
    }
    data	= {
    }

    ret = YastService.Call("YaPI::USERS::UserModify", config, data)

    logger.debug "Command returns: #{ret.inspect}"

    if ret != ""
      ok = false
      @error_string = ret
    else
      @error_id = 0
      @error_string = ""
    end
    return ok
  end

  # -------------------------------------------------------
  # add the new local user
  def add_user

    # FIXME mandatory parameters must be required on web-client side...
    config	= {
	"type"	=> [ "s", "local" ]
    }
    data	= {
	"uid"	=> [ "s", @user.uid]
    }
#FIXME convert @user hash to data hash
    data["cn"]			= [ "s", @user.cn ]		unless @user.cn.blank?
    data["userPassword"]	= [ "s", @user.userPassword ]	unless @user.userPassword.blank?

    ret = YastService.Call("YaPI::USERS::UserAdd", config, data)

    logger.debug "Command returns: #{ret.inspect}"

    return true if ret == ""
    @error_string = ret
    return false
  end

  # -------------------------------------------------------
  # delete existing local user
  def delete_user

    config	= {
	"type"	=> [ "s", "local" ],
	"uid"	=> [ "s", @user.uid ]
    }

    ret = YastService.Call("YaPI::USERS::UserDelete", config)

    return true if ret[:exit] == 0

    @error_id = ret[:exit]
    @error_string = ret[:stderr]
    return false

  end

#--------------------------------------------------------------------------------
#
# actions
#
#--------------------------------------------------------------------------------

  # GET /users
  # GET /users.xml
  # GET /users.json
  def index
    unless permission_check("org.opensuse.yast.modules.yapi.users.usersget")
      render ErrorResult.error(403, 1, "no permission") and return
    end
    get_user_list
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    unless permission_check("org.opensuse.yast.modules.yapi.users.userget")
      render ErrorResult.error(403, 1, "no permission") and return
    end
    if params[:id].blank?
      render ErrorResult.error(404, 2, "empty parameter") and return
    end
    unless get_user params[:id]
      render ErrorResult.error(404, 2, "user not found") and return
    end
  end


  # POST /users
  # POST /users.xml
  # POST /users.json
  def create
    unless permission_check("org.opensuse.yast.modules.yapi.users.useradd")
      render ErrorResult.error(403, 1, "no permission") and return
    end

    @user = User.new
    if @user.update_attributes(params[:users])
      add_user
      if @error_id!=0
        render ErrorResult.error(404, @error_id, @error_string) and return
      end
    else
      render ErrorResult.error(404, 2, "wrong parameter") and return
    end
    render :show
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    unless permission_check("org.opensuse.yast.modules.yapi.users.usermodify")
      render ErrorResult.error(403, 1, "no permission") and return
    end
    @user = User.new
    if params[:users] && params[:users][:uid]
       params[:id] = params[:users][:uid] #for sync only
    end
    get_user params[:id]
    if @user.update_attributes(params[:users])
      update_user params[:id]
      if @error_id!=0
        render ErrorResult.error(404, @error_id, @error_string) and return
      end
    else
      render ErrorResult.error(404, 2, "wrong parameter") and return
    end
    render :show
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  # DELETE /users/1.json
  def destroy
    unless permission_check("org.opensuse.yast.modules.yapi.users.userdelete")
      render ErrorResult.error(403, 1, "no permission") and return
    end
    get_user params[:id]
    delete_user
    logger.debug "DELETE: #{@user.inspect}"
    if @error_id!=0
      render ErrorResult.error(404, @error_id, @error_string) and return
    else
      render :show
    end
  end

end

