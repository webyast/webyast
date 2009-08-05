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
    parameters	= {
	# user to find
	"uid"	=> [ "s", id ],
	# list of attributes to return;
	"user_attributes"	=> [ "as", [
	    "cn", "uidNumber", "homeDirectory",
	    "grouplist", "uid", "loginShell", "groupname"
	]]
    }
    user_map = YastService.Call("YaPI::USERS::UserGet", parameters)
    # TODO check if it is not empty

    @user 	= User.new

#FIXME why User.new (user_map) does not work?

    # convert camel-cased YaST keys to ruby's under_scored ones
    @user.grouplist		= user_map["grouplist"]
    @user.home_directory	= user_map["homeDirectory"]
    @user.groupname		= user_map["groupname"]
    @user.login_shell		= user_map["loginShell"]
    @user.uid			= id
    @user.uid_number		= user_map["uidNumber"]
    @user.cn			= user_map["cn"]

    return true
  end

  # -------------------------------------------------------
  # modify existing user
  def update_user userId
    config	= {
	"type"	=> [ "s", "local" ],
	"uid"	=> [ "s", @user.uid ]
    }
    # FIXME convert ruby's under_scored keys to YaST's camel-cased ones
    data	= {
	"uid"	=> [ "s", @user.uid]
    }

    ret = YastService.Call("YaPI::USERS::UserModify", config, data)

    logger.debug "Command returns: #{ret.inspect}"

    @error_string = ret
    return (ret == "")
  end

  # -------------------------------------------------------
  # add the new local user
  def add_user

    if @user.uid.nil?
	@error_string = "Empty login name"
	return false
    end

    # FIXME mandatory parameters must be required on web-client side...
    config	= {
	"type"	=> [ "s", "local" ]
    }
    data	= {
	"uid"	=> [ "s", @user.uid]
    }
    # FIXME convert ruby's under_scored keys to YaST's camel-cased ones
    data["cn"]			= [ "s", @user.cn ]		unless @user.cn.blank?
    data["userPassword"]	= [ "s", @user.user_password ]	unless @user.user_password.blank?
    data["homeDirectory"]	= [ "s", @user.home_directory ]	unless @user.home_directory.blank?
    data["loginShell"]		= [ "s", @user.login_shell ]	unless @user.login_shell.blank?
    data["uidNumber"]		= [ "s", @user.uid_number ]	unless @user.uid_number.blank?
    data["groupname"]		= [ "s", @user.groupname ]	unless @user.groupname.blank?

    ret = YastService.Call("YaPI::USERS::UserAdd", config, data)

    logger.debug "Command returns: #{ret.inspect}"

    @error_string = ret
    return (ret == "")
  end

  # -------------------------------------------------------
  # delete existing local user
  def delete_user

    config	= {
	"type"	=> [ "s", "local" ],
	"uid"	=> [ "s", @user.uid ]
    }

    ret = YastService.Call("YaPI::USERS::UserDelete", config)

    logger.debug "Command returns: #{ret}"

    @error_string = ret
    return (ret == "")
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
      if @error_string != ""
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
      if @error_string != ""
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
    if @error_string != ""
      render ErrorResult.error(404, @error_id, @error_string) and return
    else
      render :show
    end
  end

end

