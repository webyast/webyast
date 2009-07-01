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
# FIXME this way of passing array currently fails in ruby-dbus:
#  TypeError (can't convert Array into String): 
#  /usr/lib64/ruby/vendor_ruby/1.8/dbus/type.rb:112:in `+'
    }
    users_map = YastService.Call("YaPI::USERS::UsersGet", parameters)
    if users_map.nil?
	puts "something wrong happened -------------------------------------"
    else
	users_map.each do |key, val|
	    user = User.new
	    # FIXME adapt the model to the YaPI return map
	    user.login_name	= key
	    user.full_name	= val["cn"]
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
	    "grouplist", "loginShell", "groupname"
	]]
    }
    user_map = YastService.Call("YaPI::USERS::UserGet", parameters)
    # TODO check if it is not empty
    @user = User.new
    # FIXME adapt the model to the YaPI return map
    @user.login_name	= id
    @user.full_name	= user_map["cn"]
    @user.login_shell	= user_map["loginShell"]
    @user.uid		= user_map["uidNumber"]
    @user.home_directory= user_map["homeDirectory"]
    @user.default_group	= user_map["groupname"]
    @user.grouplist	= user_map["grouplist"]

    @user.sshkey	= saveKey
    return true
  end

  def createSSH
    if @user.home_directory.blank?
      save_key = @user.sshkey
      get_user @user.login_name
      @user.sshkey = save_key
    end
    ret = @scr.read(".target.stat", "#{@user.home_directory}/.ssh/authorized_keys")
    if ret.empty?
      logger.debug "Create: #{@user.home_directory}/.ssh/authorized_keys"
      @scr.execute(["/bin/mkdir", "#{@user.home_directory}/.ssh"])      
      @scr.execute(["/bin/chown", "#{@user.login_name}", "#{@user.home_directory}/.ssh"])      
      @scr.execute(["/bin/chmod", "755", "#{@user.home_directory}/.ssh"])
      @scr.execute(["/usr/bin/touch", "#{@user.home_directory}/.ssh/authorized_keys"])      
      @scr.execute(["/bin/chown", "#{@user.login_name}", "#{@user.home_directory}/.ssh/authorized_keys"])      
      @scr.execute(["/bin/chmod", "644", "#{@user.home_directory}/.ssh/authorized_keys"])
    end
    ret = @scr.execute(["echo", "\"#{@user.sshkey}\"", ">>", "#{@user.home_directory}/.ssh/authorized_keys"])
    @error_id = ret[:exit]
    if ret[:exit] != 0
      @error_string = ret[:stderr]
      return false
    else 
      @error_string = ""
      return true
    end
  end

  def udate_user userId
    ok = true

    if not @user.sshkey.blank?
      ok = createSSH
    end

    command = ["/sbin/yast2", "users", "edit"]

    command << "cn=\"#{@user.full_name}\"" if not @user.full_name.blank?
    if not @user.groups.blank?
      grp_string = @user.groups.map { |group| group[:id] }.join(',')
      command << "grouplist=#{grp_string}"
    end
    
    command << "gid=#{@user.default_group}" if not @user.default_group.blank?
    command << "home=#{@user.home_directory}" if not @user.home_directory.blank?
    command << "shell=#{@user.login_shell}" if not @user.login_shell.blank?
    command << "username=#{userId}" if not userId.blank?
    command << "uid=#{@user.uid}" if not @user.uid.blank?
    command << "password=#{@user.password}" if not @user.password.blank?
    command << "ldap_password=#{@user.ldap_password}" if not @user.ldap_password.blank?
    command << "new_uid=#{@user.new_uid}" if not @user.new_uid.blank?
    command << "new_username=#{@user.new_login_name}" if not @user.new_login_name.blank?
    command << "type=#{@user.type}" if not @user.type.blank?
    command << "batchmode"
    ret = @scr.execute(command)
    if ret[:exit] != 0
      ok = false
      @error_id = ret[:exit]
      @error_string = ret[:stderr]
    else
      @error_id = 0
      @error_string = ""
    end
    return ok
  end

  def add_user
#    command = ["/sbin/yast2", "users", "add"]
#    command << "cn=\"#{@user.full_name}\""  if not @user.full_name.blank?
#    if not @user.groups.blank?
#      grp_string = @user.groups.map { |group| group[:id] }.join(',')
#      command << "grouplist=#{grp_string}"
#    end
#    command << "gid=#{@user.default_group}" if not @user.default_group.blank?
#    command << "home=#{@user.home_directory}" if not @user.home_directory.blank?
#    command << "shell=#{@user.login_shell}" if not @user.login_shell.blank?
#    command << "username=#{@user.login_name}" if not @user.login_name.blank?
#    command << "uid=#{@user.uid}" if not @user.uid.blank?
#    command << "password=#{@user.password}" if not @user.password.blank?
#    command << "ldap_password=#{@user.ldap_password}" if not @user.ldap_password.blank?
#    command << "no_home" if not @user.no_home.blank? and @user.no_home.eql?('true')
#    command << "type=#{@user.type}" if not @user.type.blank?
#    command << "batchmode"

    # FIXME mandatory parameters must be required on web-client side...
    config	= {
	"type"	=> [ "s", "local" ]
    }
    data	= {
	"uid"	=> [ "s", @user.login_name ]
    }
    data["cn"]			= [ "s", @user.full_name ]	unless @user.full_name.blank?
    data["userPassword"]	= [ "s", @user.password ]	unless @user.password.blank?

    ret = YastService.Call("YaPI::USERS::UserAdd", config, data)

    logger.debug "Command returns: #{ret.inspect}"

    return true if ret == ""

#    @error_id = ret[:exit] FIXME
    @error_string = ret
    return false
  end

  def delete_user
    command = ["/sbin/yast2", "users",  "delete", "delete_home"]
    command << "uid=#{@user.uid}" if not @user.uid.blank?
    command << "username=#{@user.login_name}" if not @user.login_name.blank?
    command << "ldap_password=#{@user.ldap_password}" if not @user.ldap_password.blank?
    command << "type=#{@user.type}" if not @user.type.blank?

    command << "batchmode"

    ret = @scr.execute(command)
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
    if params[:users] && params[:users][:login_name]
       params[:id] = params[:users][:login_name] #for sync only
    end
    get_user params[:id]
    if @user.update_attributes(params[:users])
      udate_user params[:id]
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

