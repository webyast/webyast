include ApplicationHelper

class UsersController < ApplicationController

#--------------------------------------------------------------------------------
#
#local methods
#
#--------------------------------------------------------------------------------


  def get_userList
    ret = scrExecute(".target.bash_output", "LANG=en.UTF-8 /sbin/yast2 users list")
     lines = ret[:stderr].split "\n"
     @users = []
     lines::each do |s|   
       user = User.new 	
       user.loginName = s
       @users << user
     end
  end

  def get_user (id)
    ret = scrExecute(".target.bash_output", "LANG=en.UTF-8 /sbin/yast2 users show username=#{id}")
     lines = ret[:stderr].split "\n"
     counter = 0
     @user = User.find(:first)
     if @user == nil
       @user = User.new
       @user.save
     end
     lines::each do |s|   
       if counter+1 <= lines.length
         case s
         when "Full Name:"
           @user.fullName = lines[counter+1].strip
         when "List of Groups:"
           @user.groups = lines[counter+1].strip
         when "Default Group:"
           @user.defaultGroup = lines[counter+1].strip
         when "Home Directory:"
           @user.homeDirectory = lines[counter+1].strip
         when "Login Shell:"
           @user.loginShell = lines[counter+1].strip
         when "Login Name:"
           @user.loginName = lines[counter+1].strip
         when "UID:"
           @user.uid = lines[counter+1].strip
         end
       end
       counter += 1
     end
  end

  def udate_user
    command = "LANG=en.UTF-8 /sbin/yast2 users edit "
    if @user.fullName && @user.fullName.length > 0
      command = command + 'cn="' + @user.fullName + '" '
    end
    if @user.groups && @user.groups.length > 0
      command += "grouplist=#{@user.groups} "
    end
    if @user.defaultGroup && @user.defaultGroup.length > 0
      command += "gid=#{@user.defaultGroup} "
    end
    if @user.homeDirectory && @user.homeDirectory.length > 0
      command += "home=#{@user.homeDirectory} "
    end
    if @user.loginShell && @user.loginShell.length > 0
      command += "shell=#{@user.loginShell} "
    end
    if @user.loginName && @user.loginName.length > 0
      command += "username=#{@user.loginName} "
    end
    if @user.uid && @user.uid.length > 0
      command += "uid=#{@user.uid} "
    end
    if @user.password && @user.password.length > 0
      command += "password=#{@user.password} "
    end
    if @user.ldapPassword && @user.ldapPassword.length > 0
      command += "ldap_password=#{@user.ldapPassword} "
    end
    if @user.newUid && @user.newUid.length > 0
      command += "new_uid=#{@user.newUid} "
    end
    if @user.newLoginName && @user.newLoginName.length > 0
      command += "new_username=#{@user.newLoginName} "
    end
    if @user.type && @user.type.length > 0
      command += "type=#{@user.type} "
    end

    ret = scrExecute(".target.bash_output", command)
    if ret[:exit] == 0
      return true
    else
      return false
    end
  end

  def add_user
    command = "LANG=en.UTF-8 /sbin/yast2 users add "
    if @user.fullName && @user.fullName.length > 0
      command = command + 'cn="' + @user.fullName + '" '
    end
    if @user.groups && @user.groups.length > 0
      command += "grouplist=#{@user.groups} "
    end
    if @user.defaultGroup && @user.defaultGroup.length > 0
      command += "gid=#{@user.defaultGroup} "
    end
    if @user.homeDirectory && @user.homeDirectory.length > 0
      command += "home=#{@user.homeDirectory} "
    end
    if @user.loginShell && @user.loginShell.length > 0
      command += "shell=#{@user.loginShell} "
    end
    if @user.loginName && @user.loginName.length > 0
      command += "username=#{@user.loginName} "
    end
    if @user.uid && @user.uid.length > 0
      command += "uid=#{@user.uid} "
    end
    if @user.password && @user.password.length > 0
      command += "password=#{@user.password} "
    end
    if @user.ldapPassword && @user.ldapPassword.length > 0
      command += "ldap_password=#{@user.ldapPassword} "
    end
    if @user.noHome && @user.noHome = "true"
      command += "no_home "
    end
    if @user.type && @user.type.length > 0
      command += "type=#{@user.type} "
    end

    ret = scrExecute(".target.bash_output", command)
    if ret[:exit] == 0
      return true
    else
      return false
    end
  end

  def add_user
    command = "LANG=en.UTF-8 /sbin/yast2 users add "
    if @user.fullName && @user.fullName.length > 0
      command = command + 'cn="' + @user.fullName + '" '
    end
    if @user.groups && @user.groups.length > 0
      command += "grouplist=#{@user.groups} "
    end
    if @user.defaultGroup && @user.defaultGroup.length > 0
      command += "gid=#{@user.defaultGroup} "
    end
    if @user.homeDirectory && @user.homeDirectory.length > 0
      command += "home=#{@user.homeDirectory} "
    end
    if @user.loginShell && @user.loginShell.length > 0
      command += "shell=#{@user.loginShell} "
    end
    if @user.loginName && @user.loginName.length > 0
      command += "username=#{@user.loginName} "
    end
    if @user.uid && @user.uid.length > 0
      command += "uid=#{@user.uid} "
    end
    if @user.password && @user.password.length > 0
      command += "password=#{@user.password} "
    end
    if @user.ldapPassword && @user.ldapPassword.length > 0
      command += "ldap_password=#{@user.ldapPassword} "
    end
    if @user.noHome && @user.noHome = "true"
      command += "no_home "
    end
    if @user.type && @user.type.length > 0
      command += "type=#{@user.type} "
    end

    ret = scrExecute(".target.bash_output", command)
    if ret[:exit] == 0
      return true
    else
      return false
    end
  end

  def delete_user
    command = "LANG=en.UTF-8 /sbin/yast2 users delete delete_home "
    if @user.uid && @user.uid.length > 0
      command += "uid=#{@user.uid} "
    end
    if @user.loginName && @user.loginName.length > 0
      command += "username=#{@user.loginName} "
    end
    if @user.ldapPassword && @user.ldapPassword.length > 0
      command += "ldap_password=#{@user.ldapPassword} "
    end
    if @user.type && @user.type.length > 0
      command += "type=#{@user.type} "
    end

    ret = scrExecute(".target.bash_output", command)
    if ret[:exit] == 0
      return true
    else
      return false
    end
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
    get_userList

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users }
      format.json { render :json => @users.to_json }
    end
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    get_user params[:id]

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user }
      format.json { render :json => @user.to_json }
    end
  end

  # GET /users/new
  # GET /users/new.xml
  def new
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/1/edit
  def edit
    get_user params[:id]
    @user.id = @user.loginName
  end

  # POST /users
  # POST /users.xml
  # POST /users.json
  def create
    @user = User.new(params[:user])

    respond_to do |format|
      if add_user
        flash[:notice] = 'User was successfully created.'
        format.html { redirect_to(users_url) }
        format.xml  { render :xml => @user, :status => :created, :location => @user }
        format.xml  { head :ok }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
        format.json { head :error }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    get_user params[:id]

    respond_to do |format|
      if @user.update_attributes(params[:user])
        if udate_user
          flash[:notice] = 'User was successfully updated.'
          format.html { redirect_to(users_url) }
          format.xml  { head :ok }
          format.json { head :ok }
        else
          flash[:notice] = 'Command has NOT been run successfully'
          format.html { redirect_to :back, :action => "show" }
          format.json { head :error }
          format.xml { head :error }
        end
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
        format.json { head :error }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  # DELETE /users/1.json
  def destroy
    get_user params[:id]
    @user.destroy
    delete_user

    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { head :ok }
      format.json  { head :ok }
    end
  end
end
