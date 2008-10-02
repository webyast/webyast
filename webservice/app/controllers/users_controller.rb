include ApplicationHelper

class UsersController < ApplicationController

  before_filter :login_required

  require "scr"
#--------------------------------------------------------------------------------
#
#local methods
#
#--------------------------------------------------------------------------------


  def get_userList
    if polkit_check( "org.opensuse.yast.webservice.read-userlist", self.current_account.login) == 0
       ret = Scr.execute("LANG=en.UTF-8 /sbin/yast2 users list")
       lines = ret[:stderr].split "\n"
       @users = []
       lines::each do |s|   
          user = User.new 	
          user.loginName = s
          @users << user
       end
    else
       @users = []
       user = User.new 	
       user.error_id = 1
       user.error_string = "no permission"
       @users << user
    end
  end

  def get_user (id)
    if @user
      saveKey = @user.sshkey
    else
      saveKey = nil
    end
    ret = Scr.execute("LANG=en.UTF-8 /sbin/yast2 users show username=#{id}")
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
     @user.sshkey = saveKey
     @user.error_id = 0
     @user.error_string = ""
  end

  def createSSH
    if @user.homeDirectory == nil || @user.homeDirectory.length == 0
      saveKey = @user.sshkey
      get_user @user.loginName
      @user.sshkey = saveKey
    end

    ret = Scr.readArg(".target.stat", "#{@user.homeDirectory}/.ssh/authorized_keys")
    if ret.length == 0
      logger.debug "Create: #{@user.homeDirectory}/.ssh/authorized_keys"
      Scr.execute("/bin/mkdir #{@user.homeDirectory}/.ssh")      
      Scr.execute("/bin/chown #{@user.loginName} #{@user.homeDirectory}/.ssh}")      
      Scr.execute("/bin/chmod 755 #{@user.homeDirectory}/.ssh}")
      Scr.execute("/usr/bin/touch #{@user.homeDirectory}/.ssh/authorized_keys")      
      Scr.execute("/bin/chown #{@user.loginName} #{@user.homeDirectory}/.ssh/authorized_keys}")      
      Scr.execute("/bin/chmod 644 #{@user.homeDirectory}/.ssh/authorized_keys}")
    end
    ret =  Scr.execute("echo \"#{@user.sshkey}\"  >> #{@user.homeDirectory}/.ssh/authorized_keys")
    if ret[:exit] != 0
      return false
    else 
      return true
    end
  end

  def udate_user userId
    ok = true

    if @user.sshkey && @user.sshkey.length > 0
      ok = createSSH
    end

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
    if userId && userId.length > 0
      command += "username=#{userId} "
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
    ret = Scr.execute(command)
    if ret[:exit] != 0
      ok = false
      @user.error_id = ret[:exit]
      @user.error_string = ret[:stderr]
    end
    return ok
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

    ret = Scr.execute(command)
    if ret[:exit] == 0
      return true
    else
      @user.error_id = ret[:exit]
      @user.error_string = ret[:stderr]
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

    ret = Scr.execute(command)
    if ret[:exit] == 0
      return true
    else
      @user.error_id = ret[:exit]
      @user.error_string = ret[:stderr]
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
    if polkit_check( "org.opensuse.yast.webservice.read-user", self.current_account.login) == 0
       get_user params[:id]
    else
       @user = User.new
       @user.error_id = 1
       @user.error_string = "no permission"
    end       

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
    if polkit_check( "org.opensuse.yast.webservice.new-user", self.current_account.login) != 0
       @user.error_id = 1
       @user.error_string = "no permission"
    end
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @user }
      format.json  { render :json => @user }
    end
  end

  # GET /users/1/edit
  def edit
    if polkit_check( "org.opensuse.yast.webservice.write-user", self.current_account.login) != 0
       @user = User.new
       @user.error_id = 1
       @user.error_string = "no permission"
    else
       get_user params[:id]
    end
  end

  # POST /users
  # POST /users.xml
  # POST /users.json
  def create
    @user = User.new(params[:user])
    if polkit_check( "org.opensuse.yast.webservice.new-user", self.current_account.login) != 0
       @user.error_id = 1
       @user.error_string = "no permission"
    else
       add_user
    end
    respond_to do |format|
      if @user.error_id == 0
         flash[:notice] = 'User was successfully created.'
         format.html { redirect_to(users_url) }
      else
         format.html { render :action => "new" }
      end
      format.xml  { render :xml => @user.to_xml( :root => "systemtime",
                    :dasherize => false) }
      format.json  { render :json => @user.to_json }
    end
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    if polkit_check( "org.opensuse.yast.webservice.write-user", self.current_account.login) != 0
       @user = User.new(params[:user])
       @user.error_id = 1
       @user.error_string = "no permission"
    else

       if params[:user] && params[:user][:loginName]
          params[:id] = params[:user][:loginName] #for sync only
       end
       get_user params[:id]
       if @user.update_attributes(params[:user])
          udate_user params[:id]
       else
          @user.error_id = 2
          @user.error_string = "wrong parameter"
       end
    end
    respond_to do |format|
       if @user.error_id == 0
          flash[:notice] = 'User was successfully updated.'
          format.html { redirect_to(users_url) }
       else
          flash[:notice] = @user.error_string
          format.html { redirect_to :back, :action => "show" }
       end
       format.xml  { render :xml => @user.to_xml( :root => "systemtime",
                     :dasherize => false) }
       format.json  { render :json => @user.to_json }
    end
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  # DELETE /users/1.json
  def destroy
    if polkit_check( "org.opensuse.yast.webservice.delete-user", self.current_account.login) != 0
       @user = User.new
       @user.error_id = 1
       @user.error_string = "no permission"
    else
       get_user params[:id]
       @user.destroy
       delete_user
       logger.debug "DELETE: #{@user.inspect}"
    end
    respond_to do |format|
       format.html { redirect_to(users_url) }
       format.xml  { render :xml => @user.to_xml( :root => "systemtime",
                     :dasherize => false) }
       format.json  { render :json => @user.to_json }
    end
  end

  # GET /users/1/edit/exportssh
  def exportssh
    if polkit_check( "org.opensuse.yast.webservice.write-user-sshkey", self.current_account.login) != 0
       @user = User.new
       @user.error_id = 1
       @user.error_string = "no permission"
    else
       get_user params[:id]
    end
    logger.debug "exportssh: #{@user.inspect}"
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @user }
    end
  end


  # GET/PUT /users/1/<single-value>
  def singleValue
    if request.get?
      # GET
      @user = User.new
      @retUser = User.new
      get_user params[:users_id]
      #initialize not needed stuff (perhaps no permissions available)
      case params[:id]
        when "defaultGroup"
          if ( polkit_check( "org.opensuse.yast.webservice.read-user", self.current_account.login) == 0 or
               polkit_check( "org.opensuse.yast.webservice.read-user-defaultgroup", self.current_account.login) == 0 ) then
             @retUser.defaultGroup = @user.defaultGroup
          else
             @retUser.error_id = 1
             @retUser.error_string = "no permission"
          end         
        when "fullName"
          if ( polkit_check( "org.opensuse.yast.webservice.read-user", self.current_account.login) == 0 or
               polkit_check( "org.opensuse.yast.webservice.read-user-fullname", self.current_account.login) == 0 ) then
             @retUser.fullName = @user.fullName
          else
             @retUser.error_id = 1
             @retUser.error_string = "no permission"
          end         
        when "groups"
          if ( polkit_check( "org.opensuse.yast.webservice.read-user", self.current_account.login) == 0 or
               polkit_check( "org.opensuse.yast.webservice.read-user-groups", self.current_account.login) == 0 ) then
             @retUser.groups = @user.groups
          else
             @retUser.error_id = 1
             @retUser.error_string = "no permission"
          end         
        when "homeDirectory"
          if ( polkit_check( "org.opensuse.yast.webservice.read-user", self.current_account.login) == 0 or
               polkit_check( "org.opensuse.yast.webservice.read-user-homedirectory", self.current_account.login) == 0 ) then
             @retUser.homeDirectory = @user.homeDirectory
          else
             @retUser.error_id = 1
             @retUser.error_string = "no permission"
          end         
        when "loginName"
          if ( polkit_check( "org.opensuse.yast.webservice.read-user", self.current_account.login) == 0 or
               polkit_check( "org.opensuse.yast.webservice.read-user-loginname", self.current_account.login) == 0 ) then
             @retUser.loginName = @user.loginName
          else
             @retUser.error_id = 1
             @retUser.error_string = "no permission"
          end         
        when "loginShell"
          if ( polkit_check( "org.opensuse.yast.webservice.read-user", self.current_account.login) == 0 or
               polkit_check( "org.opensuse.yast.webservice.read-user-loginshell", self.current_account.login) == 0 ) then
             @retUser.loginShell = @user.loginShell
          else
             @retUser.error_id = 1
             @retUser.error_string = "no permission"
          end         
        when "uid"
          if ( polkit_check( "org.opensuse.yast.webservice.read-user", self.current_account.login) == 0 or
               polkit_check( "org.opensuse.yast.webservice.read-user-uid", self.current_account.login) == 0 ) then
             @retUser.uid = @user.uid
          else
             @retUser.error_id = 1
             @retUser.error_string = "no permission"
          end         
      end
      @user = @retUser
      respond_to do |format|
        format.xml do
          render :xml => @user.to_xml( :root => "users",
            :dasherize => false )
        end
        format.json do
	  render :json => @user.to_json
        end
        format.html do
          render :file => "#{RAILS_ROOT}/app/views/users/show.html.erb"
        end
      end      
    else
      #PUT
      respond_to do |format|
        @setUser = User.new
        @user = User.new
        if @setUser.update_attributes(params[:user])
          logger.debug "UPDATED: #{@setUser.inspect}"
          ok = true
          #setting which are clear
          @user.loginName = params[:users_id]
          @user.ldapPassword = @setUser.ldapPassword
          exportSSH = false
          case params[:id]
            when "defaultGroup"
              if ( polkit_check( "org.opensuse.yast.webservice.write-user", self.current_account.login) == 0 or
                  polkit_check( "org.opensuse.yast.webservice.write-user-defaultgroup", self.current_account.login) == 0 ) then
                 @user.defaultGroup = @setUser.defaultGroup
              else
                 @user.error_id = 1
                 @user.error_string = "no permission"
              end         
            when "fullName"
              if ( polkit_check( "org.opensuse.yast.webservice.write-user", self.current_account.login) == 0 or
                   polkit_check( "org.opensuse.yast.webservice.write-user-fullname", self.current_account.login) == 0 ) then
                 @user.fullName = @setUser.fullName
              else
                 @user.error_id = 1
                 @user.error_string = "no permission"
              end         
            when "groups"
              if ( polkit_check( "org.opensuse.yast.webservice.write-user", self.current_account.login) == 0 or
                   polkit_check( "org.opensuse.yast.webservice.write-user-groups", self.current_account.login) == 0 ) then
                 @user.groups = @setUser.groups
              else
                 @user.error_id = 1
                 @user.error_string = "no permission"
              end         
            when "homeDirectory"
              if ( polkit_check( "org.opensuse.yast.webservice.write-user", self.current_account.login) == 0 or
                   polkit_check( "org.opensuse.yast.webservice.write-user-homedirectory", self.current_account.login) == 0 ) then
                 @user.homeDirectory = @setUser.homeDirectory
              else
                 @user.error_id = 1
                 @user.error_string = "no permission"
              end         
            when "newLoginName"
              if ( polkit_check( "org.opensuse.yast.webservice.write-user", self.current_account.login) == 0 or
                   polkit_check( "org.opensuse.yast.webservice.write-user-loginname", self.current_account.login) == 0 ) then
                 @user.newLoginName = @setUser.newLoginName
              else
                 @user..error_id = 1
                 @user.error_string = "no permission"
              end         
            when "loginShell"
              if ( polkit_check( "org.opensuse.yast.webservice.write-user", self.current_account.login) == 0 or
                   polkit_check( "org.opensuse.yast.webservice.write-user-loginshell", self.current_account.login) == 0 ) then
                 @user.loginShell = @setUser.loginShell
              else
                 @user.error_id = 1
                 @user.error_string = "no permission"
              end         
            when "newUid"
              if ( polkit_check( "org.opensuse.yast.webservice.write-user", self.current_account.login) == 0 or
                   polkit_check( "org.opensuse.yast.webservice.write-user-uid", self.current_account.login) == 0 ) then
                 @user.newUid = @setUser.newUid
              else
                 @user.error_id = 1
                 @user.error_string = "no permission"
              end         
            when "password"
              if ( polkit_check( "org.opensuse.yast.webservice.write-user", self.current_account.login) == 0 or
                   polkit_check( "org.opensuse.yast.webservice.write-user-password", self.current_account.login) == 0 ) then
                 @user.password = @setUser.password
              else
                 @user.error_id = 1
                 @user.error_string = "no permission"
              end         
            when "type"
              if ( polkit_check( "org.opensuse.yast.webservice.write-user", self.current_account.login) == 0 or
                   polkit_check( "org.opensuse.yast.webservice.write-user-type", self.current_account.login) == 0 ) then
                 @user.type = @setUser.type
              else
                 @user.error_id = 1
                 @user.error_string = "no permission"
              end         
            when "sshkey"
              if ( polkit_check( "org.opensuse.yast.webservice.write-user", self.current_account.login) == 0 or
                   polkit_check( "org.opensuse.yast.webservice.write-user-sshkey", self.current_account.login) == 0 ) then
                 @user.sshkey = @setUser.sshkey
                 exportSSH = true
              else
                 @user.error_id = 1
                 @user.error_string = "no permission"
              end         
            else
              logger.error "Wrong ID: #{params[:id]}"
              @user.error_id = 2
              @user.error_string = "Wrong ID: #{params[:id]}"
              ok = false
          end
          if ok
            if exportSSH
              saveUser = @user
              ok = createSSH #reads @user again
              @user = saveUser
            else
              ok = udate_user params[:users_id]
            end
          end
        else
           @user.error_id = 2
           @user.error_string = "format or internal error"
        end

        if @user.error_id == 0
           format.html { redirect_to :action => "show" }
        else
           format.html { render :action => "edit" }
        end

        format.xml do
            render :xml => @user.to_xml( :root => "user",
                     :dasherize => false )
        end
        format.json do
           render :json => @user.to_json
        end
      end
    end
  end


end


